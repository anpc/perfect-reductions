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

def tup_to_num(g)
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
def add_constraints1(p, lv, client_index, v_ind1, v_ind2, v_arr):
     L = []
     weights = {}
     v_ind_list = [v_ind1, v_ind2]
     w = [1, -1] 
     for i in range(2):
         v_ind = v_ind_list[i]
         weight = w[i]   
         for rest in itertools.product(range(2), repeat = 3):
             v_arr_new = tuple([change_one(pair, c^1, r)
                                        for (pair, c, r) in zip(v_arr, client_index, rest)])
             L.append(str((v_ind, v_arr_new)))
             weights[str((v_ind, v_arr_new))] = weight
     p.add_constraint(sum(weights[o] * lv[o] for o in L) <= 0)
     p.add_constraint(sum(-weights[o] * lv[o] for o in L) <= 0)
     # print 'added according to L = ',L   
     # is this necessary or does lv actually pass by reference ?
        
def add_constraints2(p, lv, v_ind):
    L = []
    for v_arr in product(list(product(range(2), repeat = 2)), repeat = 3):
        L.append(str((v_ind, v_arr)))
    # print 'added according to L = ',L    
    p.add_constraint(sum(lv[o] for o in L) <= 1)
    p.add_constraint(sum(-lv[o] for o in L) <= -1)
    
    
# each of the list elements is a non-empty list of triples
def generate_LP(client_index_list):
    p = MixedIntegerLinearProgram()
    p.set_objective(5)   
    lv = p.new_variable()
    lv.set_min(0)
    lv.set_max(1)
    
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
                    add_constraints1(p, lv, client_index, tuple(v1_ind), tuple(v2_ind), v_arr)

    # type 2 constraints
        
    for v_ind in itertools.product(range(2), repeat = 3):
        add_constraints2(p, lv, v_ind)
        
    p.solve()
    pairs = [t for t in p.get_values(lv).iteritems()]
    pairs = sorted(pairs)
    vlist = [y for (x,y) in pairs]
    m = matrix(QQ, 8, 64, vlist)
    sage.plot.matrix_plot.matrix_plot(m).show()
    
    # print 'lv values = '
#     m = matrix(ZZ, 8, 64, lv.values())
#     print 'lv keys = ',
#     print lv.keys()
    
    # pprint.pprint(lv.values())
    # sage.plot.matrix_plot.matrix_plot(m).show()
    return p    
            

print 'starting up'
vectors = list(itertools.product(range(2), repeat = 3))
print 'vectors = ', vectors
spread_indices = list(itertools.product(range(3), repeat = 5))
print 'spread_indices = ', spread_indices
nsteps = 0
for i in spread_indices:
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
        p = generate_LP(c_lists)
        nsteps = nsteps + 1
    if nsteps > 10:
        break
    
︡e5670c6e-a001-4024-b525-53c8f8bb2a49︡{"stdout":"starting up\n"}︡{"stdout":"vectors =  [(0, 0, 0), (0, 0, 1), (0, 1, 0), (0, 1, 1), (1, 0, 0), (1, 0, 1), (1, 1, 0), (1, 1, 1)]\n"}︡{"stdout":"spread_indices =  [(0, 0, 0, 0, 0), (0, 0, 0, 0, 1), (0, 0, 0, 0, 2), (0, 0, 0, 1, 0), (0, 0, 0, 1, 1), (0, 0, 0, 1, 2), (0, 0, 0, 2, 0), (0, 0, 0, 2, 1), (0, 0, 0, 2, 2), (0, 0, 1, 0, 0), (0, 0, 1, 0, 1), (0, 0, 1, 0, 2), (0, 0, 1, 1, 0), (0, 0, 1, 1, 1), (0, 0, 1, 1, 2), (0, 0, 1, 2, 0), (0, 0, 1, 2, 1), (0, 0, 1, 2, 2), (0, 0, 2, 0, 0), (0, 0, 2, 0, 1), (0, 0, 2, 0, 2), (0, 0, 2, 1, 0), (0, 0, 2, 1, 1), (0, 0, 2, 1, 2), (0, 0, 2, 2, 0), (0, 0, 2, 2, 1), (0, 0, 2, 2, 2), (0, 1, 0, 0, 0), (0, 1, 0, 0, 1), (0, 1, 0, 0, 2), (0, 1, 0, 1, 0), (0, 1, 0, 1, 1), (0, 1, 0, 1, 2), (0, 1, 0, 2, 0), (0, 1, 0, 2, 1), (0, 1, 0, 2, 2), (0, 1, 1, 0, 0), (0, 1, 1, 0, 1), (0, 1, 1, 0, 2), (0, 1, 1, 1, 0), (0, 1, 1, 1, 1), (0, 1, 1, 1, 2), (0, 1, 1, 2, 0), (0, 1, 1, 2, 1), (0, 1, 1, 2, 2), (0, 1, 2, 0, 0), (0, 1, 2, 0, 1), (0, 1, 2, 0, 2), (0, 1, 2, 1, 0), (0, 1, 2, 1, 1), (0, 1, 2, 1, 2), (0, 1, 2, 2, 0), (0, 1, 2, 2, 1), (0, 1, 2, 2, 2), (0, 2, 0, 0, 0), (0, 2, 0, 0, 1), (0, 2, 0, 0, 2), (0, 2, 0, 1, 0), (0, 2, 0, 1, 1), (0, 2, 0, 1, 2), (0, 2, 0, 2, 0), (0, 2, 0, 2, 1), (0, 2, 0, 2, 2), (0, 2, 1, 0, 0), (0, 2, 1, 0, 1), (0, 2, 1, 0, 2), (0, 2, 1, 1, 0), (0, 2, 1, 1, 1), (0, 2, 1, 1, 2), (0, 2, 1, 2, 0), (0, 2, 1, 2, 1), (0, 2, 1, 2, 2), (0, 2, 2, 0, 0), (0, 2, 2, 0, 1), (0, 2, 2, 0, 2), (0, 2, 2, 1, 0), (0, 2, 2, 1, 1), (0, 2, 2, 1, 2), (0, 2, 2, 2, 0), (0, 2, 2, 2, 1), (0, 2, 2, 2, 2), (1, 0, 0, 0, 0), (1, 0, 0, 0, 1), (1, 0, 0, 0, 2), (1, 0, 0, 1, 0), (1, 0, 0, 1, 1), (1, 0, 0, 1, 2), (1, 0, 0, 2, 0), (1, 0, 0, 2, 1), (1, 0, 0, 2, 2), (1, 0, 1, 0, 0), (1, 0, 1, 0, 1), (1, 0, 1, 0, 2), (1, 0, 1, 1, 0), (1, 0, 1, 1, 1), (1, 0, 1, 1, 2), (1, 0, 1, 2, 0), (1, 0, 1, 2, 1), (1, 0, 1, 2, 2), (1, 0, 2, 0, 0), (1, 0, 2, 0, 1), (1, 0, 2, 0, 2), (1, 0, 2, 1, 0), (1, 0, 2, 1, 1), (1, 0, 2, 1, 2), (1, 0, 2, 2, 0), (1, 0, 2, 2, 1), (1, 0, 2, 2, 2), (1, 1, 0, 0, 0), (1, 1, 0, 0, 1), (1, 1, 0, 0, 2), (1, 1, 0, 1, 0), (1, 1, 0, 1, 1), (1, 1, 0, 1, 2), (1, 1, 0, 2, 0), (1, 1, 0, 2, 1), (1, 1, 0, 2, 2), (1, 1, 1, 0, 0), (1, 1, 1, 0, 1), (1, 1, 1, 0, 2), (1, 1, 1, 1, 0), (1, 1, 1, 1, 1), (1, 1, 1, 1, 2), (1, 1, 1, 2, 0), (1, 1, 1, 2, 1), (1, 1, 1, 2, 2), (1, 1, 2, 0, 0), (1, 1, 2, 0, 1), (1, 1, 2, 0, 2), (1, 1, 2, 1, 0), (1, 1, 2, 1, 1), (1, 1, 2, 1, 2), (1, 1, 2, 2, 0), (1, 1, 2, 2, 1), (1, 1, 2, 2, 2), (1, 2, 0, 0, 0), (1, 2, 0, 0, 1), (1, 2, 0, 0, 2), (1, 2, 0, 1, 0), (1, 2, 0, 1, 1), (1, 2, 0, 1, 2), (1, 2, 0, 2, 0), (1, 2, 0, 2, 1), (1, 2, 0, 2, 2), (1, 2, 1, 0, 0), (1, 2, 1, 0, 1), (1, 2, 1, 0, 2), (1, 2, 1, 1, 0), (1, 2, 1, 1, 1), (1, 2, 1, 1, 2), (1, 2, 1, 2, 0), (1, 2, 1, 2, 1), (1, 2, 1, 2, 2), (1, 2, 2, 0, 0), (1, 2, 2, 0, 1), (1, 2, 2, 0, 2), (1, 2, 2, 1, 0), (1, 2, 2, 1, 1), (1, 2, 2, 1, 2), (1, 2, 2, 2, 0), (1, 2, 2, 2, 1), (1, 2, 2, 2, 2), (2, 0, 0, 0, 0), (2, 0, 0, 0, 1), (2, 0, 0, 0, 2), (2, 0, 0, 1, 0), (2, 0, 0, 1, 1), (2, 0, 0, 1, 2), (2, 0, 0, 2, 0), (2, 0, 0, 2, 1), (2, 0, 0, 2, 2), (2, 0, 1, 0, 0), (2, 0, 1, 0, 1), (2, 0, 1, 0, 2), (2, 0, 1, 1, 0), (2, 0, 1, 1, 1), (2, 0, 1, 1, 2), (2, 0, 1, 2, 0), (2, 0, 1, 2, 1), (2, 0, 1, 2, 2), (2, 0, 2, 0, 0), (2, 0, 2, 0, 1), (2, 0, 2, 0, 2), (2, 0, 2, 1, 0), (2, 0, 2, 1, 1), (2, 0, 2, 1, 2), (2, 0, 2, 2, 0), (2, 0, 2, 2, 1), (2, 0, 2, 2, 2), (2, 1, 0, 0, 0), (2, 1, 0, 0, 1), (2, 1, 0, 0, 2), (2, 1, 0, 1, 0), (2, 1, 0, 1, 1), (2, 1, 0, 1, 2), (2, 1, 0, 2, 0), (2, 1, 0, 2, 1), (2, 1, 0, 2, 2), (2, 1, 1, 0, 0), (2, 1, 1, 0, 1), (2, 1, 1, 0, 2), (2, 1, 1, 1, 0), (2, 1, 1, 1, 1), (2, 1, 1, 1, 2), (2, 1, 1, 2, 0), (2, 1, 1, 2, 1), (2, 1, 1, 2, 2), (2, 1, 2, 0, 0), (2, 1, 2, 0, 1), (2, 1, 2, 0, 2), (2, 1, 2, 1, 0), (2, 1, 2, 1, 1), (2, 1, 2, 1, 2), (2, 1, 2, 2, 0), (2, 1, 2, 2, 1), (2, 1, 2, 2, 2), (2, 2, 0, 0, 0), (2, 2, 0, 0, 1), (2, 2, 0, 0, 2), (2, 2, 0, 1, 0), (2, 2, 0, 1, 1), (2, 2, 0, 1, 2), (2, 2, 0, 2, 0), (2, 2, 0, 2, 1), (2, 2, 0, 2, 2), (2, 2, 1, 0, 0), (2, 2, 1, 0, 1), (2, 2, 1, 0, 2), (2, 2, 1, 1, 0), (2, 2, 1, 1, 1), (2, 2, 1, 1, 2), (2, 2, 1, 2, 0), (2, 2, 1, 2, 1), (2, 2, 1, 2, 2), (2, 2, 2, 0, 0), (2, 2, 2, 0, 1), (2, 2, 2, 0, 2), (2, 2, 2, 1, 0), (2, 2, 2, 1, 1), (2, 2, 2, 1, 2), (2, 2, 2, 2, 0), (2, 2, 2, 2, 1), (2, 2, 2, 2, 2)]"}︡{"stdout":"\n"}︡{"stdout":"flags = went over endings in  (0, 0, 0, 0, 0)  =  [(1, 2), (2, 1)]\nc distribution =  (0, 0, 0, 0, 0, 1, 2)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_WKCa8B.svg","show":true,"text":null,"uuid":"522eade6-48ac-4928-8fe5-1e9bd0c19c0f"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 0, 2, 1)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_AWOOUy.svg","show":true,"text":null,"uuid":"7b8bab2e-eafd-42e1-93f6-382678985180"},"once":false}︡{"stdout":"flags ="}︡{"stdout":" went over endings in  (0, 0, 0, 0, 1)  =  [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)]\nc distribution =  (0, 0, 0, 0, 1, 0, 0)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_9Aomu7.svg","show":true,"text":null,"uuid":"9b4c730a-6ffb-4148-91e7-8c06cb881ca3"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 0, 1)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_WbqVHX.svg","show":true,"text":null,"uuid":"ee33f664-718d-4e00-b9bd-ee8866fba352"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 0, 2)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_jlsPxT.svg","show":true,"text":null,"uuid":"05a27b74-f341-4cad-a19a-91d6cb7935cf"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 1, 0)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_OtETB0.svg","show":true,"text":null,"uuid":"dda2ca0b-aaf5-40fc-be73-06e95b392989"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 1, 1)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_dl3QuX.svg","show":true,"text":null,"uuid":"1c8f32ec-7a8c-41a9-bd6f-e47895772091"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 1, 2)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_HDH098.svg","show":true,"text":null,"uuid":"107d1cfe-0bbc-445f-a235-004d7a92911c"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 2, 0)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_oZrG8w.svg","show":true,"text":null,"uuid":"bfde6b28-98c8-479a-9edb-4d8f77513793"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 2, 1)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_qKdWMb.svg","show":true,"text":null,"uuid":"d3963103-337d-49c5-bf0d-2b7e745cbcc3"},"once":false}︡{"stdout":"c distribution = "}︡{"stdout":" (0, 0, 0, 0, 1, 2, 2)\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/287/tmp_9iiGDK.svg","show":true,"text":null,"uuid":"4b556612-8e80-4048-9762-4516552416bf"},"once":false}︡{"done":true}︡
︠81c75631-c8b5-42e4-aa08-f4d68c56274cs︠
    
p = MixedIntegerLinearProgram()
v = p.new_variable(real=True, nonnegative=True)
p.solve()
x, y, z = v['x'], v['y'], v['z']
type(2*x <= 0)
v = p.get_values(v)
print v.values()
print v.keys()
︡cf2758c1-3101-4d98-bdbd-62f9f9788ae3︡{"stdout":"0.0\n"}︡{"stdout":"<type 'sage.numerical.linear_functions.LinearConstraint'>\n"}︡{"stdout":"[0.0, 0.0, 0.0]\n"}︡{"stdout":"['y', 'x', 'z']\n"}︡{"done":true}︡
︠8a557a48-4e83-4a9c-90d6-5d573a2a49b4︠

︠7dcf55ec-c018-4009-8544-a64ce0b7afd1︠










