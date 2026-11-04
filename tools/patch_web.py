"""Prepara a exportação web para ser publicada como artifact do Claude.
Uso: exportar o preset "Web" para build/web/ e depois: python tools/patch_web.py
O .wasm vai comprimido como engine-gz.wasm e o .pck como pck.wasm (limite de 20 MiB por ficheiro)."""
import gzip, os, re, shutil
W = os.path.join(os.path.dirname(__file__), "..", "build", "web")
with open(os.path.join(W, "index.wasm"), "rb") as f, gzip.open(os.path.join(W, "engine-gz.wasm"), "wb", 9) as g:
    shutil.copyfileobj(f, g)
os.remove(os.path.join(W, "index.wasm"))
os.replace(os.path.join(W, "index.pck"), os.path.join(W, "pck.wasm"))
p = os.path.join(W, "index.html")
s = open(p, encoding="utf-8").read()
loader = """<script>
(function(){var of=window.fetch.bind(window);window.fetch=function(input,init){var url=typeof input==='string'?input:input.url;
if(/index\\.wasm(\\?|$)/.test(url)){return of('engine-gz.wasm',init).then(function(r){if(!r.ok)return r;var ds=r.body.pipeThrough(new DecompressionStream('gzip'));return new Response(ds,{status:200,headers:{'Content-Type':'application/wasm'}});});}
if(/index\\.pck(\\?|$)/.test(url)){return of('pck.wasm',init);}
return of(input,init);};})();
</script>
"""
s = re.sub(r"<title>.*?</title>", "<title>Pegadas na Neve</title>", s, count=1)
s = s.replace("<head>", "<head>\n" + loader, 1).replace('"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false')
open(p, "w", encoding="utf-8").write(s)
print("ok")
