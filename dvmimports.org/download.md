---
layout: page
title: "Download"
group: navigation
gallery: "ship/**/*.zip"
---

## Latest stable versions

| Version |   IDE  | Config    |    |
|---------|--------|-----------|----| {% for item in page.gallery_items %}
| {{ item | download_entry }}  | <a href="{{ item }}">download</a> | {% endfor %}


