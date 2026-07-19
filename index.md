---
layout: default
title: PeriLily
---

{% capture readme %}
{% include_relative README.md %}
{% endcapture %}

{{ readme | markdownify }}