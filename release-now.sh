#!/bin/bash

# Buduje wszystkie targety i tworzy/zastępuje release 'latest'.
# Usuwa i odtwarza tag -- licznik pobrań zeruje się, gwiazdki repozytorium zostają.

REPO_DIR="/c/Projekty/github/Tetris"
REPO="wesmar/Tetris"
TAG="latest"
DATE=$(date +"%m.%Y")

cd "$REPO_DIR" || { echo "Nie można przejść do: $REPO_DIR"; exit 1; }

echo "======================================"
echo "KROK 1: Budowanie x86 / x64 / ARM64"
echo "======================================"
powershell.exe -ExecutionPolicy Bypass -File build.ps1
if [ $? -ne 0 ]; then
    echo "Błąd budowania!"
    exit 1
fi

# Sprawdź czy binaria istnieją
for f in bin/tetris.exe bin/tetris64.exe bin/tetris_arm64.exe; do
    if [ ! -f "$f" ]; then
        echo "Brak pliku: $f"
        exit 1
    fi
done

get_kb() { local b=$(wc -c < "$1" | tr -d ' \r'); echo "$(( (b + 512) / 1024 )) KB"; }
SIZE_X86=$(get_kb   bin/tetris.exe)
SIZE_X64=$(get_kb   bin/tetris64.exe)
SIZE_ARM64=$(get_kb bin/tetris_arm64.exe)

COMMIT=$(git log --oneline -1)

echo ""
echo "======================================"
echo " tetris.exe          $SIZE_X86   (x86)"
echo " tetris64.exe        $SIZE_X64   (x64)"
echo " tetris_arm64.exe    $SIZE_ARM64  (ARM64)"
echo " Release: $TAG @ $REPO"
echo " Data:    $DATE"
echo " Commit:  $COMMIT"
echo "======================================"
echo ""
echo "Usuwa i odtwarza tag '$TAG' (Source code pokaże datę $DATE)."
echo "Licznik pobrań zostanie wyzerowany."
read -r -p "Kontynuować? [t/N] " confirm
[[ "$confirm" =~ ^[tTyY]$ ]] || { echo "Anulowano."; exit 0; }

echo ""
echo "======================================"
echo "KROK 2: Usuwanie release + tag"
echo "======================================"
gh release delete "$TAG" --repo "$REPO" --yes --cleanup-tag 2>/dev/null \
    && echo "Release i tag usunięte" \
    || echo "Release nie istniało (pierwsze tworzenie)"

echo ""
echo "======================================"
echo "KROK 3: Tworzenie nowego release"
echo "======================================"

if [ ! -f "$REPO_DIR/release-now.md" ]; then
    echo "Brak pliku release-now.md"
    exit 1
fi

export DATE SIZE_X86 SIZE_X64 SIZE_ARM64 REPO TAG
RELEASE_BODY=$(envsubst '${DATE} ${SIZE_X86} ${SIZE_X64} ${SIZE_ARM64} ${REPO} ${TAG}' < "$REPO_DIR/release-now.md")

gh release create "$TAG" \
    --repo "$REPO" \
    --title "Tetris Assembly — Release ${DATE}" \
    --notes "$RELEASE_BODY" \
    "bin/tetris.exe#tetris.exe" \
    "bin/tetris64.exe#tetris64.exe" \
    "bin/tetris_arm64.exe#tetris_arm64.exe"

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "SUKCES! (${DATE})"
    echo "======================================"
    echo "   https://github.com/$REPO/releases/tag/$TAG"
    echo ""
    echo "Assety:"
    echo "   tetris.exe           -- ${SIZE_X86}"
    echo "   tetris64.exe         -- ${SIZE_X64}"
    echo "   tetris_arm64.exe     -- ${SIZE_ARM64}"
else
    echo "Błąd tworzenia release!"
    exit 1
fi
