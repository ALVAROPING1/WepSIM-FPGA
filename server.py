from typing import cast

from flask import Flask, request
from flask_cors import CORS

from api.firmware_gen import Firmware
from api.fpga import prj
from api.uart import flash_program

app = Flask(__name__)
CORS(app)


@app.route("/build", methods=["POST"])
def build():
    try:
        data = request.get_json()
        firmware = Firmware(**data).gen()
        with open("./src/firmware/firmware.vhdl", "w") as f:
            f.write(firmware)
        prj.make()
        return {}, 200
    except Exception as e:
        return {"error": e}, 400


@app.route("/flash", methods=["POST"])
def flash():
    try:
        data = request.get_json()
        ram = cast(dict[str, str], data["data"])
        data["data"] = {int(k, 16): v for k, v in ram.items()}
        prj.prog()
        flash_program(**data)
        return {}, 200
    except Exception as e:
        return {"error": e}, 400


app.run(debug=False)
