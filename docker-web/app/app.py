from flask import Flask, request, render_template_string

import config

app = Flask(__name__)

# The studio renders a personalized greeting card. The card body is assembled by
# interpolating the visitor supplied name straight into a template string and
# then handing that string to Jinja2. Building templates from untrusted input is
# the whole vulnerability: Jinja2 evaluates whatever expression the name carries.
CARD = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Template Studio</title>
  <style>
    body { background:#101418; color:#e6edf3; font-family:system-ui,sans-serif;
           display:flex; align-items:center; justify-content:center;
           height:100vh; margin:0; }
    .card { background:#171b21; border:1px solid #262c36; border-radius:12px;
            padding:28px 40px; box-shadow:0 8px 30px rgba(0,0,0,0.5);
            max-width:640px; }
    h1 { margin:0 0 12px; font-weight:700; }
    a { color:#6cb6ff; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Welcome to the Template Studio, %s.</h1>
    <p>Your greeting card was rendered live from the name you provided.</p>
    <p><a href="/">Make another card</a></p>
  </div>
</body>
</html>"""

INDEX = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Template Studio</title>
  <style>
    body { background:#101418; color:#e6edf3; font-family:system-ui,sans-serif;
           display:flex; align-items:center; justify-content:center;
           height:100vh; margin:0; }
    .card { background:#171b21; border:1px solid #262c36; border-radius:12px;
            padding:28px 40px; box-shadow:0 8px 30px rgba(0,0,0,0.5);
            width:340px; text-align:center; }
    input { width:100%; padding:10px; margin:10px 0; border-radius:6px;
            border:1px solid #30363d; background:#0d1117; color:#e6edf3;
            box-sizing:border-box; }
    button { width:100%; padding:10px; border:0; border-radius:6px;
             background:#238636; color:#fff; font-size:15px; cursor:pointer; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Template Studio</h1>
    <form action="/card" method="get">
      <input type="text" name="name" placeholder="Your name" autofocus>
      <button type="submit">Render my card</button>
    </form>
  </div>
  <!-- TODO(reviewer): the card view still builds the greeting by dropping the
       raw name into the template string before render_template_string. Sanitize
       the name before we launch; right now the field is evaluated as a template. -->
</body>
</html>"""


@app.route("/")
def index():
    return render_template_string(INDEX)


@app.route("/card")
def card():
    name = request.args.get("name", "guest")
    # Vulnerable on purpose: the name is concatenated into the template source,
    # so any Jinja2 expression in the name is executed during rendering (SSTI).
    return render_template_string(CARD % name)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=config.LISTEN_PORT)
