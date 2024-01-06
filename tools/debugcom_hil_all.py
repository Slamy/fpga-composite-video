import os

from debugcom_hil_ebu75 import test_colorbars
from debugcom_hil_parrot import test_parrot
from debugcom_hil_secam import test_secam_stress


def upload_fpga_core():
    os.system('../gowin/upload.sh')


if __name__ == '__main__':
    upload_fpga_core()
    test_colorbars()
    upload_fpga_core()
    test_parrot()
    upload_fpga_core()
    test_secam_stress()
    print("I have finished the tests!")
