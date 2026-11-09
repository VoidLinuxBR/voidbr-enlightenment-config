# voidbr-enlightenment-config

Configuração padrão do **Enlightenment** no VoidBR Linux.

## O que o pacote instala

| Destino | Conteúdo |
|---|---|
| `/usr/share/enlightenment/data/config/voidbr/` | Perfil de sistema **VoidBR** do E (aparece em *Configurações → Perfis*) |
| `/usr/share/elementary/colors/voidbr.pal` | Paleta de cores VoidBR (Tokyo Night) para o tema flat do EFL |
| `/usr/share/elementary/config/voidbr/` | Perfil `voidbr` do Elementary (o E usa o mesmo nome de perfil) |
| `/usr/share/voidbr-enlightenment/backgrounds/voidbr.edj` | Wallpaper oficial (`voidbr-wallpaper.avif` do voidbr-wallpapers, empacotado em .edj) |
| `/usr/share/elementary/themes/voidbr.edj` | Tema VoidBR por cima do `default`: barra no topo e dock em ilha, janelas com barra fina e cantos arredondados, menus/popups/notificações em cartão, áreas de trabalho em pílulas e tela de bloqueio com relógio |
| `/etc/skel/.e/e/config/` | Perfil `voidbr` já ativo para novos usuários |
| `/etc/skel/.elementary/config/` | Tema `default` + paleta `voidbr` + ícones Tokyonight-Dark-Icons |
| `/etc/skel/.config/conky/conky.conf` | Conky com as cores VoidBR |
| `/usr/bin/voidbr-enlightenment-tweaks` | App de ajustes (GTK4): barra, aparência, papel de parede, módulos e atalhos |
| `/etc/xdg/autostart/` + `/usr/bin/start-install-void` | Pastas do usuário e atalho do instalador no live |
| `/etc/sv/acpid/conf` + `/etc/acpi/voidbr-enlightenment/` | acpid só repassa os eventos ACPI para o E (sem rodar o `handler.sh`) |
| `/etc/elogind/logind.conf.d/60-voidbr-enlightenment.conf` | elogind ignora botão de energia, suspender e tampa (quem age é o E) |

## Estrutura

```
src/
  e/voidbr/*.src        configs do E em texto (eet)
  e/voidbr/profile.desktop
  elementary/base.src   config do Elementary
  palette/voidbr.src    paleta de cores
  wallpaper/voidbr.edc  empacota o voidbr-wallpaper.avif em .edj
  theme/*.edc           tema VoidBR (barra, janelas, menus, notificações, bloqueio)
build.sh                compila src/ para o pkgdir
```

As configs do E são binárias (EET). A fonte fica em **texto** no `src/`, para dar para
revisar diffs no git. O `build.sh` gera os binários em `etc/` e `usr/`, que também são
commitados: o PKGFILE só copia, sem `makedepends`.

## Editar uma configuração

```sh
# 1. ajuste o E numa sessão de teste e exporte
eet -d ~/.e/e/config/voidbr/e.cfg config > src/e/voidbr/e.src
# 2. confira o diff (remova caminhos /home/<usuário>, histórico, etc.)
git diff src/
# 3. regenere os arquivos compilados e commite src/ + etc/ + usr/
bash build.sh .
```

Ao trocar o wallpaper no voidbr-wallpapers, rode `bash build.sh .` de novo
(ou `WALLPAPER=/caminho/imagem bash build.sh .`).

## Paleta VoidBR

Mesma base **Tokyo Night** da edição GNOME (`voidbr-tokyo-theme`) e da Waybar, com destaque verde.
O GTK usa `Tokyonight-Dark-Theme` (via xsettings do E) e os ícones são os `Tokyonight-Dark-Icons`.

| Papel | Cor |
|---|---|
| Fundo (`:bg`) | `#24283b` |
| Fundo escuro (`:bg-dark`) | `#1a1b26` |
| Texto (`:fg`) | `#a9b1d6` |
| Destaque (`:selected`) | `#9ece6a` verde |
| Destaque 2 (`:selected-alt`) | `#e0af68` amarelo |
| Azul (`:selected2`) | `#7aa2f7` |
| Vermelho (`:selected4`) | `#f7768e` |

Para testar outra paleta sem reinstalar: `elementary_config` → *Colors*.
