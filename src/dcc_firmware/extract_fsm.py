#! /usr/bin/env python
"""
Extract the Serial Link FSM from my DCC Driver
"""

import subprocess

fsm = {}
state_var = 'DUMMY_STATE' # stops it match stuff before the initial switch statement

hPDE = open('dcc_firmware.pde', 'r')
cur_state = ''

for line in hPDE:
    line = line.replace('\n','')
    line = line.lstrip()
    
    next_state = ''
    
    if line.startswith('switch'):
        start = line.find('(') + 1
        end   = line.find(')')
        
        if state_var == 'DUMMY_STATE':
            state_var = line[start:end]
        else:
            print "Found first FSM, bailing"
            break
            
        print "State Variable:", state_var
        
    elif line.startswith('case'):
        cur_state = line.split(' ')[1]
        cur_state = cur_state.replace(':','')
        
    elif line.find("%s = " % (state_var)) >= 0:
        print ":", line
        next_state = line.split('=')[1]
        next_state.replace(' ','')
        next_state = next_state.replace(';','')
        
        # Add to FSM dict
        fsm.setdefault( cur_state, []).append( next_state)
        
        print "%s -> %s" % (cur_state, next_state)
    
dot = """digraph DDC_IO_FSM {
        
%conns%

}
"""

conns = []
for state in fsm.keys():
    for next_state in fsm[state]:
        conns.append('%s -> %s;' % (state, next_state))

hDOT = open('fsm.dot','w')
hDOT.write(dot.replace('%conns%', '\n'.join(conns) ))
hDOT.close()

subprocess.Popen(['dot', 'fsm.dot' , '-Tsvg', '-o', 'fsm.svg'])

