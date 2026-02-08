#!/usr/bin/env python
# coding: utf-8

# In[14]:


import pandas as pd 
import numpy as np
import re


# In[3]:


def remove_spaces(data_base):
    for col in data_base.columns:
        if data_base[col].dtype == "object" or data_base[col].dtype.name == "String":
            data_base[col] = data_base[col].apply( lambda x : re.sub(r'\s+', " ", x.strip()) if isinstance (x , str ) else x)


# In[4]:


def titles(data_base):
    for col in data_base.columns:
        if data_base[col].dtype == "object" or data_base[col].dtype.name == "String":        
            data_base[col] = data_base[col].apply(lambda x : x.title() if isinstance (x , str) else x )
    data_base.columns = data_base.columns.str.title()

# In[5]:


def rem_col_row (data_base):
    data_base = data_base.dropna(axis = 1 , how= "all")
    data_base = data_base.dropna(axis = 0 , how= "all")
    return data_base


# In[6]:


def gen_cleaning(data_base):
    remove_spaces(data_base) 
    titles(data_base)
    rem_col_row (data_base)
    return data_base




# In[ ]:




