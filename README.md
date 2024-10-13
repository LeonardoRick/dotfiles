<h1 align="center">
  <a href="https://github.com/leonardorick/dotfiles">
    <img src="https://repository-images.githubusercontent.com/8196606/94ea9d00-7b04-11e9-8de7-a7852d3ab92d" width="400">
  </a>
  <br><br>
</h1>

<h4 align="center">
 very minimal .dotfiles implementation based on <a href="https://github.com/andreffs18/dotfiles/">andreffs18</a>
<br>Enjoy! 😄
</h4>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/github/last-commit/leonardorick/dotfiles?style=flat-square" />
  </a>
  <a href="https://github.com/leonardorick/dotfiles/blob/master/LICENSE.md">
    <img src="https://img.shields.io/github/license/leonardorick/dotfiles?color=yellow&style=flat-square" />
  </a>
</p>

<div align="center">
  <sub>Built with ❤︎ by <a href="https://leonardorick.com">Leonardo Rick</a></sub>
</div>
<br>


To setup run `./install.sh`

This will symbolic link all your files inside `dots` folder on your root `~`

The way the scripts run are simplified because of the symlink we create of the whole project to ~/.dotfiles of the computer.
This way, it's easy to access via a global variable the root of the project --> $DOTFILES;


# Karabiner Elements
First make sure to install it and after default setup ensure [this permission is enabled](https://github.com/pqrs-org/Karabiner-Elements/issues/3051#issuecomment-1355253877)


The symlink should take care of the setup if you manage to run it `make_smlinks.sh` after karabiner is already installed

It not, copy and paste this on the browser and karabiner should open allow you to import the setup.

```
karabiner://karabiner/assets/complex_modifications/import?url=https://raw.githubusercontent.com/LeonardoRick/karabiner/refs/heads/main/shortcuts.json
```

### convert jsonnet files to json
```
jsonnet shortcuts.jsonnet > shortcuts.json
```

### convert json to jsonnet
```
jsonnetfmt shortcuts.json > shortcuts.jsonnet
```


Read and study to improve terminal usage:
- https://github.com/ohmyzsh/ohmyzsh/wiki/Cheatsheet


This file may serve as a todo because probably everything here can be automated:

1 - setup git installation
