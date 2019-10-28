# -*- coding: utf-8 -*-
"""
Created on Mon Oct 28 04:08:42 2019

@author: User
"""


import pandas as pd
import numpy as np
from sodapy import Socrata



def sodapy_base(api_id,token=None):

    client = Socrata("www.datos.gov.co",
                     app_token=token)

    results = client.get(api_id,limit=1000000000)
    base_original = pd.DataFrame.from_records(results)
    return(base_original)


