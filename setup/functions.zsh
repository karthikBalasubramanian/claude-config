# ==============================================================================
# Adobe Claude Config Management Functions
# ==============================================================================

# Main setup function - sets up Claude config for current project
setup-claude-config() {
    # Enable null_glob to avoid "no matches found" errors
    setopt local_options null_glob

    local repo_dir=$(pwd)
    local claude_dir="$repo_dir/.claude"

    # 1. Validate global config exists
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        echo "❌ Error: Global Claude config not found at $CLAUDE_CONFIG_DIR"
        return 1
    fi

    # 2. Handle existing .claude directory
    if [ -e "$claude_dir" ]; then
        echo "⚠️  Existing .claude found"
        read "response?Replace it? (y/N): "
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled"
            return 1
        fi
        mv "$claude_dir" "${claude_dir}.backup.$(date +%s)"
        echo "✅ Backed up to .claude.backup.*"
    fi

    # 3. Create .claude directory
    mkdir -p "$claude_dir"
    echo "📁 Created .claude directory"

    # 4. SYMLINK: Universal components (auto-update from global)
    echo ""
    echo "🔗 Symlinking universal components (auto-update)..."

    local symlink_dirs=("agents" "commands" "hooks" "plugins" "plans")
    for dir in "${symlink_dirs[@]}"; do
        if [ -d "$CLAUDE_CONFIG_DIR/$dir" ]; then
            ln -sf "$CLAUDE_CONFIG_DIR/$dir" "$claude_dir/$dir"
            echo "   ✅ $dir/ → symlinked"
        fi
    done

    echo "   ⏭️  skills/ → intelligent copy (see below)"

    # 5. COPY: Project-specific config files
    echo ""
    echo "📦 Copying project-specific config files..."

    [ -f "$CLAUDE_CONFIG_DIR/settings.json" ] && cp "$CLAUDE_CONFIG_DIR/settings.json" "$claude_dir/settings.json" && echo "   ✅ settings.json → copied"
    [ -f "$CLAUDE_CONFIG_DIR/hooks/ruff.toml" ] && cp "$CLAUDE_CONFIG_DIR/hooks/ruff.toml" "$claude_dir/ruff.toml" && echo "   ✅ ruff.toml → copied"

    mkdir -p "$claude_dir/todos" "$claude_dir/shell-snapshots"
    echo "   ✅ Project-specific directories created"

    # 6. Detect project configuration
    echo ""
    echo "🔍 Detecting project configuration..."

    # Detect Python version
    local python_version=""
    [ -f "$repo_dir/pyproject.toml" ] && python_version=$(grep -E "requires-python.*3\.[0-9]+" "$repo_dir/pyproject.toml" | grep -oE "3\.[0-9]+" | head -1)
    [ -z "$python_version" ] && [ -f "$repo_dir/.python-version" ] && python_version=$(cat "$repo_dir/.python-version" | grep -oE "3\.[0-9]+")

    # Detect project type with intelligent scoring
    local project_type="unknown"
    local -A type_scores

    # Terraform detection
    local tf_score=0
    [ -f "$repo_dir/main.tf" ] && ((tf_score += 30))
    [ -f "$repo_dir/variables.tf" ] && ((tf_score += 20))
    [ -f "$repo_dir/outputs.tf" ] && ((tf_score += 15))
    [ -f "$repo_dir/terraform.tfvars" ] && ((tf_score += 10))
    [ -d "$repo_dir/.terraform" ] && ((tf_score += 10))
    [ -f "$repo_dir/.terraform.lock.hcl" ] && ((tf_score += 15))
    local tf_files=("$repo_dir"/**/*.tf(N))
    [ ${#tf_files[@]} -gt 0 ] && ((tf_score += 25))
    [ $tf_score -gt 0 ] && type_scores[terraform]=$tf_score

    # Python detection
    local py_score=0
    [ -f "$repo_dir/pyproject.toml" ] && ((py_score += 40))
    [ -f "$repo_dir/setup.py" ] && ((py_score += 35))
    [ -f "$repo_dir/requirements.txt" ] && ((py_score += 20))
    local py_files=("$repo_dir"/**/*.py(N))
    [ ${#py_files[@]} -gt 0 ] && ((py_score += 15))
    [ $py_score -gt 0 ] && type_scores[python]=$py_score

    # Kubernetes detection
    local k8s_score=0
    [ -f "$repo_dir/kustomization.yaml" ] && ((k8s_score += 40))
    [ -f "$repo_dir/kustomization.yml" ] && ((k8s_score += 40))
    [ -d "$repo_dir/base" ] && [ -d "$repo_dir/overlays" ] && ((k8s_score += 30))
    [ -f "$repo_dir/Chart.yaml" ] && ((k8s_score += 35))
    [ -d "$repo_dir/templates" ] && ((k8s_score += 20))
    [ -f "$repo_dir/values.yaml" ] && ((k8s_score += 15))
    local k8s_files=("$repo_dir"/**/*.yaml(N) "$repo_dir"/**/*.yml(N))
    for file in "${k8s_files[@]}"; do
        if grep -q "kind:\s*\(Deployment\|Service\|ConfigMap\|Ingress\|StatefulSet\)" "$file" 2>/dev/null; then
            ((k8s_score += 25))
            break
        fi
    done
    [ $k8s_score -gt 0 ] && type_scores[kubernetes]=$k8s_score

    # Docker detection
    local docker_score=0
    [ -f "$repo_dir/Dockerfile" ] && ((docker_score += 30))
    [ -f "$repo_dir/docker-compose.yml" ] && ((docker_score += 25))
    [ -f "$repo_dir/docker-compose.yaml" ] && ((docker_score += 25))
    [ -f "$repo_dir/.dockerignore" ] && ((docker_score += 10))
    [ $docker_score -gt 0 ] && type_scores[docker]=$docker_score

    # Determine PRIMARY and SECONDARY types
    local primary_type=""
    local secondary_types=()
    local max_score=0

    for type in "${(@k)type_scores}"; do
        local score=${type_scores[$type]}
        if [ $score -gt $max_score ]; then
            max_score=$score
            primary_type=$type
        fi
    done

    for type in "${(@k)type_scores}"; do
        local score=${type_scores[$type]}
        if [ "$type" != "$primary_type" ] && [ $score -ge 15 ]; then
            secondary_types+=($type)
        fi
    done

    if [ -n "$primary_type" ]; then
        project_type="$primary_type"
        [ ${#secondary_types[@]} -gt 0 ] && project_type="$primary_type (+ ${secondary_types[*]})"
    fi

    echo "   Project Type: $project_type"
    echo "   Python Version: ${python_version:-N/A}"

    # 7. Intelligent skill copying based on project type
    echo ""
    echo "🎯 Copying relevant security skills..."
    echo ""
    read "skill_mode?Choose skill mode - (A)uto-detect / (M)anual select / (F)ull copy [default: A]: "
    skill_mode=${skill_mode:-A}  # Default to auto-detect

    mkdir -p "$claude_dir/skills"

    # Handle full copy mode
    if [[ "$skill_mode" =~ ^[Ff]$ ]]; then
        echo ""
        echo "   📦 Copying ALL skills (48 files, ~55k tokens)..."
        cp -r "$CLAUDE_CONFIG_DIR/skills/"* "$claude_dir/skills/"
        echo "   ✅ All skills copied"
    # Handle manual selection mode
    elif [[ "$skill_mode" =~ ^[Mm]$ ]]; then
        echo ""
        echo "   Manual skill selection:"
        echo ""

        # Core skills (always recommended)
        echo "   Core skills (recommended):"
        read "copy_core?   Copy foundations + services + audit? (Y/n): "
        if [[ ! "$copy_core" =~ ^[Nn]$ ]]; then
            local core_skills=("adobe-security-foundations" "adobe-security-services" "adobe-security-audit")
            for skill in "${core_skills[@]}"; do
                [ -d "$CLAUDE_CONFIG_DIR/skills/$skill" ] && cp -r "$CLAUDE_CONFIG_DIR/skills/$skill" "$claude_dir/skills/"
            done
            echo "   ✅ Core skills copied"
        fi

        # Language skills
        echo ""
        echo "   Language skills:"
        read "langs?   Which languages? (python,nodejs,java,rust,cpp,php,ruby or 'all'): "
        if [[ "$langs" != "" ]]; then
            mkdir -p "$claude_dir/skills/adobe-security-lang/references"
            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/SKILL.md" ] && \
                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/SKILL.md" "$claude_dir/skills/adobe-security-lang/"

            if [[ "$langs" == "all" ]]; then
                cp -r "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/references/"* "$claude_dir/skills/adobe-security-lang/references/"
                echo "   ✅ All language skills copied"
            else
                IFS=',' read -rA lang_array <<< "$langs"
                for lang in "${lang_array[@]}"; do
                    lang=$(echo "$lang" | xargs)  # trim whitespace
                    if [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/references/${lang}.md" ]; then
                        cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/references/${lang}.md" \
                           "$claude_dir/skills/adobe-security-lang/references/"
                        echo "   ✅ ${lang}.md"
                    fi
                done
            fi
        fi

        # Cloud skills
        echo ""
        echo "   Cloud/Infrastructure skills:"
        read "clouds?   Which platforms? (aws,azure,gcp,k8s,terraform,cicd or 'all'): "
        if [[ "$clouds" != "" ]]; then
            mkdir -p "$claude_dir/skills/adobe-security-cloud/references"
            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/SKILL.md" ] && \
                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/SKILL.md" "$claude_dir/skills/adobe-security-cloud/"

            if [[ "$clouds" == "all" ]]; then
                cp -r "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/"* "$claude_dir/skills/adobe-security-cloud/references/"
                echo "   ✅ All cloud skills copied"
            else
                IFS=',' read -rA cloud_array <<< "$clouds"
                for cloud in "${cloud_array[@]}"; do
                    cloud=$(echo "$cloud" | xargs)
                    case "$cloud" in
                        aws)
                            for f in aws-*.md; do
                                [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" ] && \
                                    cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" \
                                       "$claude_dir/skills/adobe-security-cloud/references/"
                            done
                            echo "   ✅ AWS skills"
                            ;;
                        azure)
                            for f in azure-*.md; do
                                [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" ] && \
                                    cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" \
                                       "$claude_dir/skills/adobe-security-cloud/references/"
                            done
                            echo "   ✅ Azure skills"
                            ;;
                        gcp)
                            for f in gcp-*.md; do
                                [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" ] && \
                                    cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/$f" \
                                       "$claude_dir/skills/adobe-security-cloud/references/"
                            done
                            echo "   ✅ GCP skills"
                            ;;
                        k8s|kubernetes)
                            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/kubernetes.md" ] && \
                                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/kubernetes.md" \
                                   "$claude_dir/skills/adobe-security-cloud/references/"
                            echo "   ✅ Kubernetes"
                            ;;
                        terraform|tf)
                            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/terraform.md" ] && \
                                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/terraform.md" \
                                   "$claude_dir/skills/adobe-security-cloud/references/"
                            echo "   ✅ Terraform"
                            ;;
                        cicd)
                            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/cicd.md" ] && \
                                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/cicd.md" \
                                   "$claude_dir/skills/adobe-security-cloud/references/"
                            echo "   ✅ CI/CD"
                            ;;
                    esac
                done
            fi
        fi
    # Handle auto-detect mode (default)
    else
        echo ""
        echo "   🤖 Auto-detecting project requirements..."

        # Always copy core skills (universal)
        local core_skills=("adobe-security-foundations" "adobe-security-services" "adobe-security-audit")
        for skill in "${core_skills[@]}"; do
            if [ -d "$CLAUDE_CONFIG_DIR/skills/$skill" ]; then
                cp -r "$CLAUDE_CONFIG_DIR/skills/$skill" "$claude_dir/skills/"
                echo "   ✅ $skill (core)"
            fi
        done

        # Copy language-specific skills based on detection
        local -A lang_skills
        lang_skills[python]="python"
        lang_skills[nodejs]="nodejs"
        lang_skills[java]="java"
        lang_skills[rust]="rust"
        lang_skills[cpp]="c cpp"
        lang_skills[php]="php"
        lang_skills[ruby]="ruby"

        # Detect languages in project
        local detected_langs=()
        [ ${#py_files[@]} -gt 0 ] && detected_langs+=("python")
        [ -f "$repo_dir/package.json" ] && detected_langs+=("nodejs")
        [ -f "$repo_dir/pom.xml" ] || [ -f "$repo_dir/build.gradle" ] && detected_langs+=("java")
        [ -f "$repo_dir/Cargo.toml" ] && detected_langs+=("rust")
        local cpp_files=("$repo_dir"/**/*.{cpp,cc,h,hpp}(N))
        [ ${#cpp_files[@]} -gt 0 ] && detected_langs+=("cpp")
        local php_files=("$repo_dir"/**/*.php(N))
        [ ${#php_files[@]} -gt 0 ] && detected_langs+=("php")
        local ruby_files=("$repo_dir"/**/*.rb(N))
        [ ${#ruby_files[@]} -gt 0 ] || [ -f "$repo_dir/Gemfile" ] && detected_langs+=("ruby")

        # Copy detected language skills
        if [ ${#detected_langs[@]} -gt 0 ]; then
            # Copy the language skill directory structure
            mkdir -p "$claude_dir/skills/adobe-security-lang/references"
            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/SKILL.md" ] && \
                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/SKILL.md" "$claude_dir/skills/adobe-security-lang/"

            for lang in "${detected_langs[@]}"; do
                local skill_files=(${=lang_skills[$lang]})
                for skill_file in "${skill_files[@]}"; do
                    if [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/references/${skill_file}.md" ]; then
                        cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-lang/references/${skill_file}.md" \
                           "$claude_dir/skills/adobe-security-lang/references/"
                        echo "   ✅ adobe-security-lang/${skill_file}.md"
                    fi
                done
            done
        fi

        # Copy cloud/infrastructure skills based on detection
        local copy_cloud_skills=false
        local -a cloud_skill_files=()

        # Detect cloud providers and infrastructure (exclude .claude to avoid false positives)
        if grep -rq --exclude-dir=.claude "aws" "$repo_dir" 2>/dev/null || \
           [ -f "$repo_dir/.aws" ] || \
           grep -rq --exclude-dir=.claude "amazonaws.com" "$repo_dir" 2>/dev/null; then
            cloud_skill_files+=("aws-compute" "aws-database" "aws-iam" "aws-monitoring" "aws-network" "aws-secrets" "aws-storage")
            copy_cloud_skills=true
        fi

        if grep -rq --exclude-dir=.claude "azure" "$repo_dir" 2>/dev/null || \
           grep -rq --exclude-dir=.claude "azurecr.io" "$repo_dir" 2>/dev/null; then
            cloud_skill_files+=("azure-compute" "azure-identity" "azure-network" "azure-storage")
            copy_cloud_skills=true
        fi

        if grep -rq --exclude-dir=.claude "gcp\|google-cloud\|gcr.io" "$repo_dir" 2>/dev/null; then
            cloud_skill_files+=("gcp-compute" "gcp-iam" "gcp-network" "gcp-storage")
            copy_cloud_skills=true
        fi

        # Terraform
        if [ $tf_score -gt 0 ]; then
            cloud_skill_files+=("terraform")
            copy_cloud_skills=true
        fi

        # Kubernetes
        if [ $k8s_score -gt 0 ]; then
            cloud_skill_files+=("kubernetes")
            copy_cloud_skills=true
        fi

        # CI/CD detection
        if [ -d "$repo_dir/.github/workflows" ] || \
           [ -f "$repo_dir/.gitlab-ci.yml" ] || \
           [ -f "$repo_dir/Jenkinsfile" ] || \
           [ -f "$repo_dir/.circleci/config.yml" ]; then
            cloud_skill_files+=("cicd")
            copy_cloud_skills=true
        fi

        # Copy cloud skills if detected
        if [ "$copy_cloud_skills" = true ]; then
            mkdir -p "$claude_dir/skills/adobe-security-cloud/references"
            [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/SKILL.md" ] && \
                cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/SKILL.md" "$claude_dir/skills/adobe-security-cloud/"

            # Remove duplicates
            local -a unique_cloud_files=()
            for file in "${cloud_skill_files[@]}"; do
                if [[ ! " ${unique_cloud_files[*]} " =~ " ${file} " ]]; then
                    unique_cloud_files+=("$file")
                fi
            done

            for skill_file in "${unique_cloud_files[@]}"; do
                if [ -f "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/${skill_file}.md" ]; then
                    cp "$CLAUDE_CONFIG_DIR/skills/adobe-security-cloud/references/${skill_file}.md" \
                       "$claude_dir/skills/adobe-security-cloud/references/"
                    echo "   ✅ adobe-security-cloud/${skill_file}.md"
                fi
            done
        fi
    fi

    # 8. Customize config files
    if [ -n "$python_version" ] && [ -f "$claude_dir/ruff.toml" ]; then
        echo ""
        echo "⚙️  Customizing config..."
        local py_target="py${python_version//./}"
        sed -i '' "s/target-version = \"py[0-9]\+\"/target-version = \"$py_target\"/" "$claude_dir/ruff.toml" 2>/dev/null
        echo "   ✅ Set Ruff target to Python $python_version"
    fi

    # 9. Add to .gitignore
    echo ""
    if [ -f "$repo_dir/.gitignore" ]; then
        grep -qxF '.claude' "$repo_dir/.gitignore" 2>/dev/null || echo ".claude" >> "$repo_dir/.gitignore"
        echo "✅ Updated .gitignore"
    else
        echo ".claude" > "$repo_dir/.gitignore"
        echo "✅ Created .gitignore"
    fi

    # 10. Create metadata
    cat > "$claude_dir/.setup-info" << EOF
# Adobe Claude Config Setup
# Source: $CLAUDE_CONFIG_DIR
# Date: $(date)
# Project: $(basename $repo_dir)
# Type: $project_type
# Python: ${python_version:-N/A}
EOF

    # 11. Calculate skill statistics
    local skill_count=$(find "$claude_dir/skills" -name "*.md" -type f 2>/dev/null | wc -l | xargs)
    local skill_size=$(du -sh "$claude_dir/skills" 2>/dev/null | cut -f1)

    # 12. Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 Claude config setup complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Configuration:"
    echo "   Repository: $(basename $repo_dir)"
    echo "   Project Type: $project_type"
    echo "   Python Version: ${python_version:-N/A}"
    echo ""
    echo "🔗 Symlinked (auto-updates):"
    echo "   • agents/ commands/ hooks/ plugins/ plans/"
    echo ""
    echo "📦 Copied (customizable):"
    echo "   • ruff.toml settings.json"
    echo ""
    echo "🎯 Skills copied:"
    echo "   • $skill_count files ($skill_size)"
    echo "   • Estimated token usage: ~$((skill_count * 1000)) tokens"
    echo ""
}

# Update all projects with Claude configs
update-all-claude-configs() {
    local default_dir="$HOME/Documents/work"
    local search_dir="$default_dir"

    echo "🔄 Updating all repos with Claude configs..."
    echo ""
    echo "Default search directory: $default_dir"
    read "response?Use this directory? (Y/n): "

    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo ""
        read "custom_dir?Enter directory path: "
        if [ -z "$custom_dir" ]; then
            echo "❌ No directory provided"
            return 1
        fi
        search_dir="${custom_dir/#\~/$HOME}"  # Expand tilde
    fi

    if [ ! -d "$search_dir" ]; then
        echo "❌ Error: Directory not found: $search_dir"
        return 1
    fi

    echo ""
    echo "📁 Searching in: $search_dir"
    echo ""

    local repos=($(find "$search_dir" -type d -name ".claude" -maxdepth 5 2>/dev/null | sort))

    # Exclude the global config directory itself
    local filtered_repos=()
    local global_config_dir=$(dirname "$CLAUDE_CONFIG_DIR")
    for claude_path in "${repos[@]}"; do
        local repo_dir=$(dirname "$claude_path")
        if [ "$repo_dir" != "$global_config_dir" ]; then
            filtered_repos+=("$claude_path")
        fi
    done
    repos=("${filtered_repos[@]}")

    if [ ${#repos[@]} -eq 0 ]; then
        echo "❌ No repos with .claude configs found"
        return 1
    fi

    echo "Found ${#repos[@]} repos with Claude configs:"
    for claude_path in "${repos[@]}"; do
        local repo_dir=$(dirname "$claude_path")
        echo "   • $(basename $repo_dir)"
    done

    echo ""
    read "response?Update all? (y/N): "

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        return 1
    fi

    echo ""
    for claude_path in "${repos[@]}"; do
        local repo_dir=$(dirname "$claude_path")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📍 Updating: $(basename $repo_dir)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        cd "$repo_dir"
        setup-claude-config
        echo ""
    done

    echo "✅ All repos updated!"
}

# Clean up all .claude.backup.* directories
clean-claude-backups() {
    local default_dir="$HOME/Documents/work"
    local search_dir="$default_dir"

    echo "🧹 Finding Claude backup directories..."
    echo ""
    echo "Default search directory: $default_dir"
    read "response?Use this directory? (Y/n): "

    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo ""
        read "custom_dir?Enter directory path: "
        if [ -z "$custom_dir" ]; then
            echo "❌ No directory provided"
            return 1
        fi
        search_dir="${custom_dir/#\~/$HOME}"  # Expand tilde
    fi

    if [ ! -d "$search_dir" ]; then
        echo "❌ Error: Directory not found: $search_dir"
        return 1
    fi

    echo ""
    echo "📁 Searching in: $search_dir"
    echo ""

    local backups=($(find "$search_dir" -type d -name ".claude.backup.*" 2>/dev/null | sort))

    if [ ${#backups[@]} -eq 0 ]; then
        echo "✅ No Claude backups found"
        return 0
    fi

    echo "Found ${#backups[@]} backup directories:"
    echo ""

    local current_project=""
    for backup_path in "${backups[@]}"; do
        local project_dir=$(dirname "$backup_path")
        local project_name=$(basename "$project_dir")
        local backup_name=$(basename "$backup_path")
        local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)

        if [ "$project_name" != "$current_project" ]; then
            [ -n "$current_project" ] && echo ""
            echo "📁 $project_name:"
            current_project="$project_name"
        fi

        echo "   • $backup_name ($backup_size)"
    done

    echo ""
    echo "⚠️  This will permanently delete all backup directories"
    read "response?Continue? (y/N): "

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        return 1
    fi

    echo ""
    local count=0
    for backup_path in "${backups[@]}"; do
        echo "🗑️  Removing: $(basename $(dirname $backup_path))/$(basename $backup_path)"
        rm -rf "$backup_path"
        ((count++))
    done

    echo ""
    echo "✅ Cleaned up $count backup directories!"
}

# Show status of Claude config in current repo
claude-config-status() {
    local repo_dir=$(pwd)
    local claude_dir="$repo_dir/.claude"

    if [ ! -d "$claude_dir" ]; then
        echo "❌ No .claude directory found in $(basename $repo_dir)"
        echo "   Run 'setup-claude-config' to initialize"
        return 1
    fi

    echo "📊 Claude Config Status: $(basename $repo_dir)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    echo "🔗 Symlinked Components:"
    for item in agents commands hooks skills plugins plans; do
        if [ -L "$claude_dir/$item" ]; then
            local target=$(readlink "$claude_dir/$item")
            echo "   ✅ $item/ → $(basename $(dirname $target))/$(basename $target)"
        else
            echo "   ❌ $item/ (not symlinked)"
        fi
    done

    echo ""
    echo "📦 Copied Config Files:"
    for item in ruff.toml settings.json; do
        if [ -f "$claude_dir/$item" ]; then
            echo "   ✅ $item"
        else
            echo "   ❌ $item (missing)"
        fi
    done

    echo ""

    if [ -f "$claude_dir/.setup-info" ]; then
        echo "ℹ️  Setup Information:"
        grep -E "^# (Type|Python|Date):" "$claude_dir/.setup-info" | sed 's/^# /   /'
    fi

    echo ""
}
