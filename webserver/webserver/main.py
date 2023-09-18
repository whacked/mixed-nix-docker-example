import os
import toolz as z
import json
import subprocess as subp
from fastapi import FastAPI
from sample_private_repo.core import mad_adder


app = FastAPI()


def get_gocomponent_readout():
    result = subp.run(
        [os.environ['GOCOMPONENT_BINARY_PATH']],
        capture_output=True,
        text=True)
    return result.stdout.strip()


@app.get("/")
def read_root():
    add_result = json.loads(mad_adder(1, 2, 3))
    go_status = get_gocomponent_readout()
    return z.merge(
        {"Hello": "World"},
        {"Go": go_status},
        add_result,
    )

