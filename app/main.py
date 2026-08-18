from flask import Flask, jsonify

app = Flask(__name__)



@app.route("/")
def hello():
    return jsonify(message="Hello from your GitHub Actions learning project!")


@app.route("/health")
def health():
    """Used by CI smoke tests and container health checks later in the roadmap."""
    return jsonify(status="ok"), 200


def add(a, b):
    test_var = 2
    test_var_2 = "this is to see if lint will catch"
    """A trivial function so we have something obvious to unit test."""
    return a + b


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
