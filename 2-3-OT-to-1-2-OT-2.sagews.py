︠d7d05283-2842-485a-9a03-7f0ef91252c0︠
%md
# This project explores the construction of 2-out-of-3-OT from 1-of-2-OT

Here we make $T$ parallel calls to the OT oracles.

We start with $T = 3$

## Problem representation:

$C_1,C_2,C_3$ are the client's valid inputs.

From client's correctness, each 6-tuple of bits is assigned to some $(x1,x2,x3)$ triple.

The assignments should create an independent set in a graph with $2^{2T+3}$ veritces.

There is an edge between $v_g$ and ${v'}_{g'}$ iff. $g$ and $g'$ differ of a pair $(i,j)=[3]\setminus \{k\}$ of bits, but $v[c_k] \ne v'[c_k]$.
︡4dfc1cbd-2917-4c36-8301-9f53e8f37c45︡{"done":true,"md":"# This project explores the construction of 2-out-of-3-OT from 1-of-2-OT\n\nHere we make $T$ parallel calls to the OT oracles.\n\nWe start with $T = 3$\n\n## Problem representation:\n\n$C_1,C_2,C_3$ are the client's valid inputs.\n\nFrom client's correctness, each 6-tuple of bits is assigned to some $(x1,x2,x3)$ triple.\n\nThe assignments should create an independent set in a graph with $2^{2T+3}$ veritces.\n\nThere is an edge between $v_g$ and ${v'}_{g'}$ iff. $g$ and $g'$ differ of a pair $(i,j)=[3]\\setminus \\{k\\}$ of bits, but $v[c_k] \\ne v'[c_k]$."}
︠71951939-ef54-4de0-b65f-e2a9a1bfda7f︠
import itertools
import pprint

# TODO: change hardcoded 3 into T everywhere in the code

def tup_2_num(g):
    (ind, v_arr) = g
    return 256*ind[0] + 128*ind[1] + 64*ind[2] + v_arr[2][1] + 2*v_arr[2][0] + 4*v_arr[1][1] + 8*v_arr[1][0] + 16*v_arr[0][1] + 32*v_arr[0][0]

def change_one(pair, index, new_value):
    """Return new tuple with one element modified."""
    new_pair = list(pair)
    new_pair[index] = new_value
    return tuple(new_pair)

def product(*args, **kwargs):
    return list(itertools.product(*args, **kwargs))

# v_arr has the right value at c projection fixed
def add_constraints1(constraint_list, client_index, v_ind1, v_ind2, v_arr):
     weights = {}
     v_ind_list = [v_ind1, v_ind2]
     w = [1, -1] 
     L = [0 for i in range(512)]   
     for i in range(2):
         v_ind = v_ind_list[i]
         weight = w[i]   
         for rest in itertools.product(range(2), repeat = 3):
             v_arr_new = tuple([change_one(pair, c^1, r)
                                        for (pair, c, r) in zip(v_arr, client_index, rest)])
             L[tup_2_num((v_ind, v_arr_new))] = weight
     constraint_list.append(tuple(L + [0]))
     constraint_list.append(tuple([-x for x in L] + [0]))   
        
def add_constraints2(constraint_list, v_ind):
    L = [0 for i in range(512)]
    for v_arr in product(list(product(range(2), repeat = 2)), repeat = 3):
        L[tup_2_num((v_ind, v_arr))] = -1
    constraint_list.append(tuple(L + [1]))
    constraint_list.append(tuple([-x for x in L] + [-1]))
    # print 'added according to L = ',L    
    # p.add_constraint(sum(lv[o] for o in L) <= 1)
    # p.add_constraint(sum(-lv[o] for o in L) <= -1)

def add_var_constraints(constraint_list):
    # add a 0 at the end
    L = [0 for i in range(513)]
    for i in range(512):
        L[i] = 1
        constraint_list.append(tuple(L))
        L[i] = 0
    
# each of the list elements is a non-empty list of triples
def generate_LP(client_index_list):
    print 'generating LP..'
    constraint_list = []
    
    # type 1 constraints
    for k in range(3):
        for (x,y) in itertools.product(range(2), repeat = 2):
            for client_index in c_lists[k]:
                for v_arr_c in itertools.product(range(2), repeat = 3):
                    v_arr = [change_one((0, 0), c, r) for (c, r) in zip(client_index, v_arr_c)]
                    v1_ind = [0,0,0]
                    v2_ind = [0,0,0]
                    v1_ind[k] = 0
                    v2_ind[k] = 1
                    v1_ind[(k+1) % 3] = v2_ind[(k+1) % 3] = x
                    v1_ind[(k+2) % 3] = v2_ind[(k+2) % 3] = x  
                    add_constraints1(constraint_list, client_index, tuple(v1_ind), tuple(v2_ind), v_arr)

    # type 2 constraints
        
    for v_ind in itertools.product(range(2), repeat = 3):
        add_constraints2(constraint_list, v_ind)
        
    add_var_constraints(constraint_list)
    p = Polyhedron(constraint_list)
    for q in p.Vrepresentation():
        print(q)
   

print 'starting up'
vectors = list(itertools.product(range(2), repeat = 3))
print 'vectors = ', vectors
spread_indices = list(itertools.product(range(3), repeat = 5))
# print 'spread_indices = ', spread_indices
nsteps = 0
for i in spread_indices:
    print 'started with i = ',i
    1/0
    break
    flag1 = (1 in i)
    flag2 = (1 in i)
    endings = []
    print 'flags =',
    if flag1 and flag2:
        endings = list(itertools.product(range(3), repeat = 2))
    elif flag1 and not flag2:
        endings = [(2,0),(2,1),(2,2),(0,2),(1,2)]
    elif flag2 and not flag1:
        endings = [(1,0),(1,1),(1,2),(0,1),(2,1)]
    else:
        endings = [(1,2),(2,1)]
    print 'went over endings in ',i,' = ',endings    
    for j in endings:
        c_distr = i + j
        c_lists = [[(0,0,0)],[],[]]
        for (t,d) in enumerate(c_distr):
            [d].append(vectors[t+1])
        print 'c distribution = ',c_distr    
        generate_LP(c_lists)
        nsteps = nsteps + 1
    if nsteps > 10:
        break

︡5b5e2018-88b0-45a0-a2ab-e819241fa766︡
︠81c75631-c8b5-42e4-aa08-f4d68c56274cs︠
    
p = MixedIntegerLinearProgram()
v = p.new_variable(real=True, nonnegative=True)
p.solve()
x, y, z = v['x'], v['y'], v['z']
type(2*x <= 0)
v = p.get_values(v)
print v.values()
print v.keys()
p = Polyhedron(ieqs = [(1,2,4), (3,5,7), (4,20,9)])
for q in p.Vrepresentation():
    print(q)
print p
︡565bb28c-064a-41aa-be16-0090ccaec2a9︡{"stdout":"0.0\n"}︡{"stdout":"<type 'sage.numerical.linear_functions.LinearConstraint'>\n"}︡{"stdout":"[0.0, 0.0, 0.0]\n"}︡{"stdout":"['y', 'x', 'z']\n"}︡{"stdout":"A ray in the direction (2, -1)\nA ray in the direction (-9, 20)\nA vertex at (-7/62, -6/31)\n"}︡{"stdout":"A 2-dimensional polyhedron in QQ^2 defined as the convex hull of 1 vertex and 2 rays\n"}︡{"done":true}︡
︠71174db8-2a24-4e5e-8e81-7aab1ad101b3︠
banner()
︡6677ce74-e192-444b-ba18-a578bf66fb15︡{"stdout":"┌────────────────────────────────────────────────────────────────────┐\n│ SageMath version 8.0, Release Date: 2017-07-21                     │\n│ Type \"notebook()\" for the browser-based notebook interface.        │\n│ Type \"help()\" for help.                                            │\n└────────────────────────────────────────────────────────────────────┘\n"}︡{"done":true}︡
︠8a557a48-4e83-4a9c-90d6-5d573a2a49b4︠

︠7dcf55ec-c018-4009-8544-a64ce0b7afd1︠










