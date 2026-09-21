+++
date = '2026-09-07T22:14:06-03:00'
draft = false
title = 'levantando blog con hugo'
description = ''
author = 'emeCe'
category = 'log'
tags = ['hugo', 'howto']
+++

Paso a paso para la generación de estructura de carpetas, contenido de los archivos, el `docker-compose.yml` y el script (`hugo.sh`) para administrar el stack.

## 1. Estructura de directorios

Desde la raíz del proyecto, crear las carpetas base:

```bash
mkdir -p archetypes
mkdir -p content/blog
mkdir -p layouts/_default
```

Y los archivos:

```bash
touch hugo.toml
touch archetypes/default.md
touch content/_index.md
touch content/about.md
touch content/blog/_index.md
touch content/blog/first-post.md
touch layouts/_default/baseof.html
touch layouts/_default/single.html
touch layouts/_default/list.html
touch layouts/index.html
touch layouts/_default/about.html
touch docker-compose.yml
touch hugo.sh
touch .gitignore
```

## 2. Configuración del sitio (`hugo.toml`)

En la raíz, el archivo de configuración con el título del sitio y el menú de navegación:

```toml
baseURL = 'https://blogName.github.io/'
locale = 'latam'
title = 'bLogging'

[[menus.main]]
  name = 'Home'
  pageRef = '/'
  weight = 8

[[menus.main]]
  name = 'About'
  pageRef = '/about'
  weight = 16

[[menus.main]]
  name = 'Blog'
  pageRef = '/blog'
  weight = 24
```

## 3. Archetype para nuevos posts

`archetypes/default.md` define el front matter que se usa cada vez que se crea un post nuevo (por ejemplo con `hugo new blog/mi-post.md`):

```toml
+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
description = ''
author = 'emeCe'
category = ''
tags = []
+++
```

## 4. Contenido (`content/`)

### 4.1 Home

`content/_index.md`:

```toml
+++
title = 'Home'
+++
```

### 4.2 About

`content/about.md`:

```toml
+++
title = 'About'
subtitle = ''
layout = 'about'
+++

About. Página de ejemplo.
```

### 4.3 Sección Blog

`content/blog/_index.md`:

```toml
+++
title = 'Blog'
+++
```

### 4.4 Primer post

Y este mismo post, `content/blog/primer-post.md`, con el front matter de arriba (`title`, `description`, `author`, `category`, `tags`).

## 5. Layouts (`layouts/`)

Hugo, sin un theme instalado, busca las plantillas en `layouts/`. Definí las mínimas necesarias.

### 5.1 Layout base

`layouts/_default/baseof.html`: el esqueleto HTML común (nav, estilos inline básicos, footer) que envuelve a todas las páginas:

```go-html-template
<!DOCTYPE html>
<html lang="{{ .Site.Language.Locale | default "es" }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} · {{ .Site.Title }}{{ end }}</title>
  {{ with .Description }}<meta name="description" content="{{ . }}">{{ end }}
  <style>
    :root { color-scheme: light dark; }
    body { max-width: 40rem; margin: 2rem auto; padding: 0 1rem; font-family: system-ui, sans-serif; line-height: 1.6; }
    nav { display: flex; gap: 1rem; margin-bottom: 2rem; }
    nav a { text-decoration: none; }
    nav a[aria-current="page"] { font-weight: bold; text-decoration: underline; }
    footer { margin-top: 3rem; font-size: 0.85rem; opacity: 0.7; }
    article + article { margin-top: 2rem; padding-top: 2rem; border-top: 1px solid currentColor; }
    time { font-size: 0.85rem; opacity: 0.7; }
  </style>
</head>
<body>
  <nav>
    {{ range .Site.Menus.main.ByWeight }}
      <a href="{{ .URL }}" {{ if $.IsMenuCurrent "main" . }}aria-current="page"{{ end }}>{{ .Name }}</a>
    {{ end }}
  </nav>

  <main>
    {{ block "main" . }}{{ end }}
  </main>

  <footer>
    &copy; {{ now.Format "2006" }} {{ .Site.Title }}
  </footer>
</body>
</html>
```

### 5.2 Página individual (posts)

`layouts/_default/single.html`:

```go-html-template
{{ define "main" }}
  <article>
    <h1>{{ .Title }}</h1>
    {{ with .Date }}<time datetime="{{ .Format "2006-01-02" }}">{{ .Format "02 Jan 2006" }}</time>{{ end }}
    {{ .Content }}
  </article>
{{ end }}
```

### 5.3 Listados (ej. `/blog`)

`layouts/_default/list.html`:

```go-html-template
{{ define "main" }}
  <h1>{{ .Title }}</h1>
  {{ .Content }}

  {{ range .Pages.ByDate.Reverse }}
    <article>
      <h2><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
      {{ with .Date }}<time datetime="{{ .Format "2006-01-02" }}">{{ .Format "02 Jan 2006" }}</time>{{ end }}
      {{ with .Params.description }}<p>{{ . }}</p>{{ end }}
    </article>
  {{ end }}
{{ end }}
```

### 5.4 Home

`layouts/index.html`, que muestra los últimos 5 posts del blog:

```go-html-template
{{ define "main" }}
  {{ .Content }}

  {{ $blog := .Site.GetPage "blog" }}
  {{ with $blog }}
    <h2>Últimos posts</h2>
    <ul>
      {{ range first 5 .Pages.ByDate.Reverse }}
        <li>
          <a href="{{ .RelPermalink }}">{{ .Title }}</a>
          {{ with .Date }} — <time datetime="{{ .Format "2006-01-02" }}">{{ .Format "02 Jan 2006" }}</time>{{ end }}
        </li>
      {{ end }}
    </ul>
  {{ end }}
{{ end }}
```

### 5.5 Layout de About

`layouts/_default/about.html` (usado porque `content/about.md` tiene `layout = 'about'` en el front matter):

```go-html-template
{{ define "main" }}
  <article>
    <h1>{{ .Title }}</h1>
    {{ with .Params.subtitle }}<p><em>{{ . }}</em></p>{{ end }}
    {{ .Content }}
  </article>
{{ end }}
```

## 6. `docker-compose.yml`

Usar la imagen oficial `ghcr.io/gohugoio/hugo` y montar el proyecto entero dentro del contenedor:

```yaml
services:
  hugo:
    image: ghcr.io/gohugoio/hugo
    working_dir: /project
    entrypoint: ["/bin/sh", "-c"]
    command:
      - >
        git submodule update --init --recursive &&
        hugo server -D --port 1313 --baseURL http://localhost:${HUGO_PORT:-1313}/
    volumes:
      - .:/project
    ports:
      - "${HUGO_PORT:-1313}:1313"
```

- `git submodule update --init --recursive` inicializa submódulos (útil si en algún momento se agrega un theme como submódulo).
- `hugo server -D` levanta el servidor de desarrollo incluyendo drafts (`-D`).
- El puerto es configurable con la variable de entorno `HUGO_PORT` (por defecto `1313`).

## 7. Script `hugo.sh`

```bash
#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

docker_up() {
  docker info >/dev/null 2>&1
}

ensure_orbstack() {
  docker_up && return 0
  open -ga OrbStack
  for _ in $(seq 1 60); do
    docker_up && return 0
    sleep 1
  done
  return 1
}

start() {
  ensure_orbstack
  docker compose up -d
}

stop() {
  docker_up && docker compose down || true
}

restart() {
  stop
  start
}

clean() {
  docker_up && docker compose down -v --remove-orphans || true
  rm -rf "$ROOT_DIR/public" "$ROOT_DIR/resources" "$ROOT_DIR/.hugo_build.lock"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  clean) clean ;;
  *) exit 1 ;;
esac
```

```bash
chmod +x hugo.sh
```

## 8. `.gitignore`

Para no versionar los artefactos que genera Hugo ni temporales:

```gitignore
public/
resources/
.hugo_build.lock
.Ds_store
```

## 9. Levantar el sitio

Verificado todo lo anterior, levantar el blog local:

```bash
./hugo.sh start
```
Ingresar a [http://localhost:1313](http://localhost:1313). Los cambios en `content/` o `layouts/` se reflejan solos gracias al live reload de `hugo server`.

Para detenerlo:

```bash
./hugo.sh stop
```