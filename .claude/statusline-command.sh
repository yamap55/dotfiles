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

# 4行目: セッション名一覧（SendMessage の宛先として使うため）
# 先頭 ▶ が自分、末尾 * は busy
self_id=$(echo "$input" | jq -r '.session_id // empty')
sessions_dir="$HOME/.claude/sessions"
if [ -d "$sessions_dir" ]; then
    # sessions/*.json は Claude Code の非公開の内部レジストリ。形式が変わっても
    # statusLine 全体を壊さないよう、読めなければ黙って4行目を出さない
    # 区切りは US(0x1f)。タブ等の空白は read で連続区切り扱いになり空フィールドが潰れる
    rows=$(jq -r -n --arg self "$self_id" '
      [inputs]
      | map(select((.name // "") != "" and .nameSource != null))
      | map(. + {is_self: (.sessionId == $self)})
      | sort_by([(if .is_self then 0 else 1 end), -(.updatedAt // 0)])
      | .[]
      | [ (.pid|tostring),
          (.procStart|tostring),
          # ステータス行の幅が限られるため詰める（jq の文字列操作は文字単位なので多バイト文字が壊れない）
          (if (.name|length) > 16 then .name[0:16] + "…" else .name end),
          (.status // ""),
          (.is_self|tostring) ]
      | join("\u001f")
    ' "$sessions_dir"/*.json 2>/dev/null)

    session_names=""
    declare -A seen_names=()
    while IFS=$'\037' read -r pid proc_start name status is_self; do
        [ -n "$pid" ] || continue
        # 終了済みセッションの除外。PID 使い回しに備えて /proc の starttime(22番目)も突き合わせる
        [ "$(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null)" = "$proc_start" ] || continue
        # 同名セッションは1つだけ出す（名前が宛先なので、並べても区別できない）
        [ -z "${seen_names[$name]}" ] || continue
        seen_names[$name]=1

        if [ "$is_self" = "true" ]; then
            # 自分は statusLine 実行中に必ず busy になるので * は付けない
            name="▶${name}"
        elif [ "$status" = "busy" ]; then
            name="${name}*"
        fi
        session_names="${session_names}${session_names:+  }${name}"
    done <<< "$rows"

    [ -n "$session_names" ] && printf "💬 %s\n" "$session_names"
fi
