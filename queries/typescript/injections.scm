; extends

((template_string) @injection.content
  (#lua-match? @injection.content "%/[%*]%s*glsl%s*%*%/")
  (#set! injection.language "glsl"))
