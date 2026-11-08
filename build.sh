#!/usr/bin/env bash
# build.sh - compila as fontes em texto (src/) do voidbr-enlightenment-config
#
# Uso: bash build.sh .        (regenera os arquivos compilados dentro do próprio repositório)
#      bash build.sh <destdir>  (gera em outro diretório, para teste)
#   Os arquivos gerados em etc/ e usr/ são commitados junto com o src/; o PKGFILE só copia.
#   Gera dentro de <destdir>:
#     usr/share/enlightenment/data/config/voidbr/   perfil de sistema "VoidBR" do E
#     usr/share/elementary/colors/voidbr.pal        paleta de cores VoidBR (EFL >= 1.26)
#     usr/share/voidbr-enlightenment/backgrounds/   wallpaper .edj (do voidbr-wallpapers)
#     etc/skel/.e/e/config/                         perfil voidbr já ativo para novos usuários
#     usr/share/elementary/config/voidbr/           perfil voidbr do Elementary
#     etc/skel/.elementary/config/{voidbr,standard} tema flat + paleta voidbr + ícones Tokyonight
#
# Requer (só na máquina de quem regenera): efl (eet, edje_cc) e voidbr-wallpapers.
# Para editar uma config: altere o .src correspondente e reconstrua o pacote.
# Para extrair de uma sessão real: eet -d ~/.e/e/config/standard/e.cfg config > src/e/voidbr/e.src

set -euo pipefail

red=$'\e[31m'
green=$'\e[32m'
yellow=$'\e[33m'
reset=$'\e[0m'

srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src"
destdir="${1:?uso: bash build.sh <destdir>}"
profile="voidbr"

msg()  { printf '%s[+]%s %s\n' "${green}" "${reset}" "$*"; }
warn() { printf '%s[-]%s %s\n' "${yellow}" "${reset}" "$*"; }
die()  { printf '%s[x]%s %s\n' "${red}" "${reset}" "$*" >&2; exit 1; }

command -v eet >/dev/null || die "eet não encontrado (instale o pacote efl)"

# eet_compile <saida.cfg> <chave> <entrada.src>
eet_compile() {
	install -d "$(dirname "$1")"
	eet -e "$1" "$2" "$3" 1 || die "falha ao compilar $3"
}

# eet_raw <saida.cfg> <texto>   (profile.cfg guarda só o nome do perfil, sem compressão)
eet_raw() {
	local tmp
	tmp="$(mktemp)"
	printf '%s' "$2" >"$tmp"
	install -d "$(dirname "$1")"
	eet -i "$1" config "$tmp" 0 || die "falha ao gerar $1"
	rm -f "$tmp"
}

# 1. perfil de sistema do E
sysprof="${destdir}/usr/share/enlightenment/data/config/${profile}"
msg "Perfil de sistema do E: ${profile}"
for src in "${srcdir}/e/${profile}"/*.src; do
	eet_compile "${sysprof}/$(basename "${src%.src}").cfg" config "$src"
done
install -Dm644 "${srcdir}/e/${profile}/profile.desktop" "${sysprof}/profile.desktop"
[[ -f "${srcdir}/e/${profile}/voidbr-profile.png" ]] &&
	install -Dm644 "${srcdir}/e/${profile}/voidbr-profile.png" "${sysprof}/voidbr-profile.png"

# 2. skel: perfil voidbr já selecionado (evita o assistente de primeira execução)
msg "Skel do E"
eet_raw "${destdir}/etc/skel/.e/e/config/profile.cfg" "${profile}"
install -d "${destdir}/etc/skel/.e/e/config/${profile}"
cp -a "${sysprof}"/*.cfg "${destdir}/etc/skel/.e/e/config/${profile}/"

# 3. elementary: tema flat + paleta voidbr
#    O E usa como perfil do Elementary o mesmo nome do perfil do E ("voidbr"), então a
#    config vai no perfil voidbr (sistema e skel) e também no standard (apps fora do E).
msg "Paleta e configuração do Elementary"
eet_compile "${destdir}/usr/share/elementary/colors/${profile}.pal" palette "${srcdir}/palette/${profile}.src"
eet_compile "${destdir}/usr/share/elementary/config/${profile}/base.cfg" config "${srcdir}/elementary/base.src"
install -Dm644 "${srcdir}/e/${profile}/profile.desktop" "${destdir}/usr/share/elementary/config/${profile}/profile.desktop"
for p in "${profile}" standard; do
	install -Dm644 "${destdir}/usr/share/elementary/config/${profile}/base.cfg" \
		"${destdir}/etc/skel/.elementary/config/${p}/base.cfg"
done
eet_raw "${destdir}/etc/skel/.elementary/config/profile.cfg" "${profile}"

# 4. wallpaper (o E só aceita .edj: empacota o papel de parede do voidbr-wallpapers)
#    pode ser trocado com: WALLPAPER=/caminho/imagem.png bash build.sh <destdir>
wallpaper="${WALLPAPER:-/usr/share/backgrounds/voidbr/voidbr-wallpaper.avif}"

# be32 <arquivo> <offset> - lê um inteiro big-endian de 4 bytes
be32() { echo $((16#$(od -An -tx1 -j"$2" -N4 "$1" | tr -d ' \n'))); }

# img_size <arquivo> - imprime "largura altura" (PNG: IHDR, AVIF/HEIF: caixa ispe)
img_size() {
	local off
	if [[ "$(od -An -c -j1 -N3 "$1" | tr -d ' ')" == "PNG" ]]; then
		echo "$(be32 "$1" 16) $(be32 "$1" 20)"
	elif off=$(grep -obUa ispe "$1" | head -1 | cut -d: -f1) && [[ -n "$off" ]]; then
		echo "$(be32 "$1" $((off + 8))) $(be32 "$1" $((off + 12)))"
	else
		echo "16 9" # formato sem leitura de tamanho: assume 16:9
	fi
}

if [[ -f "$wallpaper" ]]; then
	command -v edje_cc >/dev/null || die "edje_cc não encontrado (necessário para o wallpaper)"
	read -r w h < <(img_size "$wallpaper")
	msg "Wallpaper ${wallpaper##*/} (${w}x${h})"
	install -d "${destdir}/usr/share/voidbr-enlightenment/backgrounds"
	edje_cc -DIMG_FILE="\"${wallpaper##*/}\"" -DIMG_W="${w}.0" -DIMG_H="${h}.0" \
		-id "$(dirname "$wallpaper")" \
		"${srcdir}/wallpaper/voidbr.edc" \
		"${destdir}/usr/share/voidbr-enlightenment/backgrounds/voidbr.edj" ||
		die "falha ao compilar o wallpaper"
else
	warn "${wallpaper} não encontrado (voidbr-wallpapers) - o E usará o fundo padrão do tema"
fi

# eet e edje_cc criam arquivos com modo 0600; os usuários precisam ler
for dir in usr/share/enlightenment/data/config/${profile} usr/share/elementary/colors usr/share/elementary/config/${profile} \
	usr/share/voidbr-enlightenment etc/skel/.e etc/skel/.elementary; do
	[[ -d "${destdir}/${dir}" ]] && chmod -R u=rwX,go=rX "${destdir}/${dir}"
done

msg "Concluído em ${destdir}"
