#!/bin/bash
# 拡張機能監視スクリプト
# 用途: 許可されていない拡張機能をチェック

# 許可された拡張機能リスト
ALLOWED_EXTENSIONS=(
    "golang.go"
    "oderwat.indent-rainbow"
    "mosapride.zenkaku"
    "shardulm94.trailing-spaces"
    "usernamehw.errorlens"
    "formulahendry.code-runner"
    "aaron-bond.better-comments"
    "wayou.vscode-todo-highlight"
    "mhutchie.git-graph"
    "pkief.material-icon-theme"
    "ms-ceintl.vscode-language-pack-ja"
    "yzhang.markdown-all-in-one"
    "bierner.markdown-preview-github-styling"
    # Codespaces基盤が自動でインストールする標準拡張(禁止対象ではない)
    "github.codespaces"
    "github.github-vscode-theme"
    "github.vscode-pull-request-github"
)

# AI補完系の禁止拡張機能
FORBIDDEN_EXTENSIONS=(
    "github.copilot"
    "github.copilot-chat"
    "github.copilot-labs"
    "github.copilot-nightly"
    "visualstudioexptteam.vscodeintellicode"
    "visualstudioexptteam.intellicode-api-usage-examples"
    "tabnine.tabnine-vscode"
    "codeium.codeium"
    "amazonwebservices.aws-toolkit-vscode"
)

echo "🔍 拡張機能チェック中..."
echo ""

# インストール済み拡張機能を取得
# 新しいVS Code CLIは「Codespaces: <名前> にインストールされている拡張機能:」等の
# 見出し行と、各拡張機能行の先頭に "  - " という箇条書きプレフィックスを付けて
# グループ化出力することがあるため、それらを取り除いてIDだけの行に正規化する。
RAW_INSTALLED=$(code --list-extensions 2>/dev/null)

if [ -z "$RAW_INSTALLED" ]; then
    echo "⚠️  拡張機能リストを取得できませんでした"
    exit 0
fi

INSTALLED=$(echo "$RAW_INSTALLED" | sed -E 's/^[[:space:]]*-[[:space:]]*//' | grep -Ei '^[a-z0-9][a-z0-9._-]*\.[a-z0-9._-]+$')

if [ -z "$INSTALLED" ]; then
    echo "⚠️  拡張機能リストの解析に失敗しました(出力形式が変更された可能性があります)"
    echo "--- 生の出力 ---"
    echo "$RAW_INSTALLED"
    exit 0
fi

# 禁止拡張機能のチェック
FOUND_FORBIDDEN=0
echo "❌ 禁止されている拡張機能:"
for ext in "${FORBIDDEN_EXTENSIONS[@]}"; do
    if echo "$INSTALLED" | grep -qi "^$ext\$"; then
        echo "  - $ext"
        FOUND_FORBIDDEN=1
    fi
done

if [ $FOUND_FORBIDDEN -eq 0 ]; then
    echo "  なし ✅"
fi
echo ""

# 許可されていない拡張機能のチェック
echo "⚠️  許可リストにない拡張機能:"
FOUND_UNAUTHORIZED=0
while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # 許可リストにあるかチェック
    IS_ALLOWED=0
    for allowed in "${ALLOWED_EXTENSIONS[@]}"; do
        if [ "$ext_lower" = "$allowed" ]; then
            IS_ALLOWED=1
            break
        fi
    done

    # 禁止リストにあるかチェック（既に報告済み）
    IS_FORBIDDEN=0
    for forbidden in "${FORBIDDEN_EXTENSIONS[@]}"; do
        if [ "$ext_lower" = "$forbidden" ]; then
            IS_FORBIDDEN=1
            break
        fi
    done

    if [ $IS_ALLOWED -eq 0 ] && [ $IS_FORBIDDEN -eq 0 ]; then
        echo "  - $ext"
        FOUND_UNAUTHORIZED=1
    fi
done <<< "$INSTALLED"

if [ $FOUND_UNAUTHORIZED -eq 0 ]; then
    echo "  なし ✅"
fi
echo ""

# 結果サマリー
if [ $FOUND_FORBIDDEN -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚨 禁止されている拡張機能が検出されました"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "以下のコマンドで削除してください:"
    echo ""
    for ext in "${FORBIDDEN_EXTENSIONS[@]}"; do
        if echo "$INSTALLED" | grep -qi "^$ext\$"; then
            echo "  code --uninstall-extension $ext"
        fi
    done
    echo ""
    echo "または、Codespaceを再起動すると自動削除されます。"
    echo ""
    exit 1
elif [ $FOUND_UNAUTHORIZED -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  許可リストにない拡張機能があります"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "必要な場合は教員に確認してください。"
    echo ""
    exit 0
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ すべての拡張機能が適切です"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
fi
