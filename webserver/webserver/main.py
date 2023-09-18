import toolz as z
import json
from fastapi import FastAPI
from sample_private_repo.core import mad_adder


app = FastAPI()

@app.get("/")
def read_root():
    add_result = json.loads(mad_adder(1, 2, 3))
    return z.merge(
        {"Hello": "World"},
        add_result,
    )

