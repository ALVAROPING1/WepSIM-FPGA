from typing import cast

from flask import Flask, request
from flask_cors import CORS

from api.firmware import Firmware
from api.fpga import prj
from api.uart import flash_program

app = Flask("WepSIM FPGA Server")
CORS(app)


@app.route("/build", methods=["POST"])
def build():
    data = request.get_json()
    firmware = Firmware.from_json(data).gen()
    with open("./src/firmware/firmware.vhdl", "w") as f:
        f.write(firmware)
    prj.make()
    return {"status": "Build OK"}, 200


@app.route("/flash", methods=["POST"])
def flash():
    data = request.get_json()
    ram = cast(dict[str, str], data["data"])
    data["data"] = {int(k, 16): v for k, v in ram.items()}
    prj.prog()
    flash_program(**data)
    return {"status": "Flash OK"}, 200


app.run(debug=False)
