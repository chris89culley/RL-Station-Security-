#!/usr/bin/env python
# coding: utf-8

# In[38]:


import pandas as pd

from pandas.core.common import flatten

import numpy as np
np.set_printoptions(suppress=True)

data = pd.read_csv ('../Experiments/model experiment-table.csv', skiprows=6)

#get data for different agents
security = data.iloc[:, 16:]
criminal = data.iloc[:, 5:16]
meta = data.iloc[:,:5]


# In[ ]:





# In[ ]:





# In[39]:


criminal


# In[40]:


#converts memory from one string to an array of strings for each item in memory. Then sort according to last seen 
def sort_memory(row):
    
    new_row = row.split('] [')
    new_row[0] = new_row[0][2:]
    new_row[-1] = new_row[-1][:-2]
    
    n_values = len(new_row)
    
    
    new_row = np.array(new_row)
    new_row = new_row[::-1]
    
    return(new_row)

#create new array for memory
memory_security = security['memory-security']
memory_criminal = criminal['memory-criminal']

memory_security = memory_security.apply(sort_memory)
memory_criminal = memory_criminal.apply(sort_memory)


# In[41]:


#pad memory
def padded_memory(memory, memory_size, printing=False):
    
    length = memory.shape[0]
    
    #create array to put data into
    padding = np.zeros((length,memory_size*6))
    
    #go through each row in memory
    for row in range(length):
        if printing == True:
            print(row)
        memory_items = []
        #for each memorised person
        for item in range(len(memory[row])):
            #get array, and split it into numbers
            value = memory[row][item]
            split = value.strip('[')
            split = split.split(' ')
            items_needed = []
            #select items and deal with nobodys if they exist
            if split[0] != "nobody":
                items_needed.append(split[2:5])
                items_needed.append(split[9:])
            elif split[0] == "nobody":
                items_needed.append(split[1:4])
                items_needed.append(split[8:])
            #put them into an array for all items in that row of the memory
            items_needed = np.array(list(flatten(items_needed)),dtype=float)
            memory_items.append(items_needed)
        
        #flatten memory item array (it's an array of arrays atm)
        memory_items = np.array(list(flatten(memory_items)),dtype=float)
        #this truncates the memory if we want to
        memory_items = memory_items[:memory_size*6]
        #put memory items into the padded array
        padding[row,:memory_items.shape[0]] = memory_items

    return(padding)


# In[42]:


memory_size = 50

padded_criminal_memory = padded_memory(memory_criminal,memory_size)
padded_security_memory = padded_memory(memory_security,memory_size)


# In[43]:


#creates input data with the padded memory items and other items pulled from data
other_items_criminal = criminal[["current-x-cor-criminal","current-y-cor-criminal","criminal-cash","current-platform-criminal"]].values
other_items_security = security[["current-x-cor-security","current-y-cor-security","current-platform-security"]].values

n_data_points_crim  = padded_criminal_memory.shape[0]
n_data_points_sec = padded_security_memory.shape[0]

n_additional_inputs_crim = other_items_criminal.shape[1]
n_additional_inputs_sec = other_items_security.shape[1]


input_data_crim = np.zeros((n_data_points_crim,memory_size*6+n_additional_inputs_crim))
input_data_sec = np.zeros((n_data_points_sec,memory_size*6+n_additional_inputs_sec))

input_data_crim[:,:memory_size*6] = padded_criminal_memory
input_data_crim[:,memory_size*6:] = other_items_criminal

input_data_sec[:,:memory_size*6] = padded_security_memory
input_data_sec[:,memory_size*6:] = other_items_security


# In[44]:


print(input_data_sec)
print(input_data_crim.shape)


# In[45]:


target_security = security[['target-security']].values
objective_security = security[['objective-security']].values

target_criminal = criminal[['target-criminal']].values
objective_criminal = criminal[['objective-criminal']].values

#doesn't take the padded memory as an input, takes the sort_memory output 
def get_one_hot(target,objective,memory,memory_size):
    
    n_data_points = memory.shape[0]
    
    #create an array for one-hot indices
    one_hot_indices = np.zeros(n_data_points)
    
    #for each in objective insert according index to indices 
    #try-except deals with a value error when the target can't be found as an item in the memory
    for i in range(n_data_points):
        if objective[i] == 'investigate':
            index = np.where(memory[i] == target[i][1:-1])
            try:
                one_hot_indices[i] = index[0]
            except ValueError:
                one_hot_indices[i] = 0
        if objective[i] == 'arrest_target' or objective[i] == 'steal_from_target':
            index = np.where(memory[i] == target[i][1:-1])
            try:
                one_hot_indices[i] = memory_size + index[0]
            except ValueError:
                one_hot_indices[i] = 0
        if objective[i] == 'explore':
            one_hot_indices[i] = memory_size*2
        if objective[i] == 'leave':
            one_hot_indices[i] = memory_size*2 + 1
        

    one_hot_indices = one_hot_indices.astype(int)
    one_hot = np.zeros((n_data_points_sec, one_hot_indices.max()+1))
    one_hot[np.arange(one_hot_indices.size),one_hot_indices] = 1
    
    return(one_hot)

one_hot_sec = get_one_hot(target_security,objective_security,memory_security,memory_size)
one_hot_crim = get_one_hot(target_criminal,objective_criminal,memory_criminal,memory_size)
        


# In[ ]:





# In[54]:


#save to file

np.savetxt("../Data/target_sec.csv", one_hot_sec, delimiter=",")
np.savetxt("../Data/target_crim.csv", one_hot_crim, delimiter=",")
np.savetxt("../Data/input_data_sec.csv", input_data_sec, delimiter=",")
np.savetxt("../Data/input_data_crim.csv", input_data_crim, delimiter=",")


# In[48]:





# In[ ]:





# In[ ]:




