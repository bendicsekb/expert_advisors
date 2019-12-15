import time

from DWX_ZeroMQ_Connector_v2_0_1_RC8 import DWX_ZeroMQ_Connector

_zmq = DWX_ZeroMQ_Connector()

_zmq._DWX_MTX_SUBSCRIBE_MARKETDATA_()

for i in range(100):
    print(_zmq._Market_Data_DB)
    time.sleep(1)

""" Az a nagy lófasz helyzet van, hogy valamiért a kliens nem kap vissza adatot, lehet hogy neki kéne kérnie? """