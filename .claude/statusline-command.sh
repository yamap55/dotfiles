#!/bin/bash
# Claude Code statusLine スクリプト

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# 1行目: フルパス（$HOME を ~ に置換）
dir="$cwd"
if [[ "$dir" == "$HOME"* ]]; then
    dir="~${dir#$HOME}"
fi
printf "📁 %s\n" "$dir"

# 2行目: Gitリポジトリ名 | ブランチ名（Gitリポジトリでない場合は省略）
git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
if [ -z "$git_branch" ]; then
    # タグやdetached HEADの場合
    git_branch=$(git -C "$cwd" describe --tags --exact-match HEAD 2>/dev/null)
fi

if [ -n "$git_branch" ]; then
    # リポジトリ名をリモートURLから取得し、なければトップレベルのフォルダ名を使用
    remote_url=$(git -C "$cwd" remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        repo_name=$(basename "$remote_url" .git)
    else
        repo_name=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)")
    fi
    printf "🐙 %s  |  🌿 %s\n" "$repo_name" "$git_branch"
fi

# 3行目: コンテキスト使用量バーグラフ とモデル名
# used_percentage は事前計算済みフィールド（メッセージがない場合は null）
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')

if [ -n "$used_pct" ]; then
    # 小数点以下を切り捨てて整数に変換
    used_int=$(printf "%.0f" "$used_pct")
    # バーグラフ生成（10文字固定）
    filled=$(( used_int * 10 / 100 ))
    bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $(( 10 - filled ))); do bar="${bar}░"; done
    printf "🧠 %s %d%%  ⚡ %s\n" "$bar" "$used_int" "$model_name"
else
    printf "⚡ %s\n" "$model_name"
fi
