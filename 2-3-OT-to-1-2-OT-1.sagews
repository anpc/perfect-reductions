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
︠71951939-ef54-4de0-b65f-e2a9a1bfda7fr︠
import itertools
import pprint
import random

from __future__ import division

# TODO: change hardcoded 3 into T everywhere in the code

def get_rand_dir():
    l = [random.randint(0,9) for i in range(512)]
    s = sum(l)
    # print 'returning ',[float(x)/s for x in l]
    return [float(x)/s for x in l]
    
def tup_to_num(g):
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
             v_arr_new = tuple([change_one(pair, 1-c, r)
                                        for (pair, c, r) in zip(v_arr, client_index, rest)])
            # print 'v_arr_new = ',v_arr_new   
             L.append(str((v_ind, v_arr_new)))
             weights[str((v_ind, v_arr_new))] = weight
     # print 'added constraint ',L           
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
    lv = p.new_variable()
    lv.set_min(0)
    
    # type 1 constraints
    for k in range(3):
        for (x,y) in itertools.product(range(2), repeat = 2):
            for client_index in c_lists[k]:
                print 'client_index,k',client_index,',',k
                for v_arr_c in itertools.product(range(2), repeat = 3):
                    # print 'k,(x,y),client_index,v_arr_c =',k,',',x,y,',',client_index,',',v_arr_c
                    v_arr = [change_one((0, 0), c, r) for (c, r) in zip(client_index, v_arr_c)]
                    v1_ind = [0,0,0]
                    v2_ind = [0,0,0]
                    v1_ind[k] = 0
                    v2_ind[k] = 1
                    v1_ind[(k+1) % 3] = v2_ind[(k+1) % 3] = x
                    v1_ind[(k+2) % 3] = v2_ind[(k+2) % 3] = y  
                    # print 'v_arr = ',v_arr
                    add_constraints1(p, lv, client_index, tuple(v1_ind), tuple(v2_ind), v_arr)

    # type 2 constraints
    print 'ADDING T2 CONSTRAINTS'    
    for v_ind in itertools.product(range(2), repeat = 3):
        add_constraints2(p, lv, v_ind)
    
    # objective
    for i in range(100):
        print 'random solution # ',i
        L = []
        rand_dir = get_rand_dir()
        for v_ind in itertools.product(range(2), repeat = 3):
            for v_arr in product(list(product(range(2), repeat = 2)), repeat = 3):
                L.append(str((v_ind, v_arr)))

        p.set_objective(sum(lv[d]*rand_dir[i] for (i,d) in enumerate(L)))
        # p.set_objective(5)    

        # plhd = p.polyhedron()
        # print plhd
        p.solve()
        print "The solution is"
        pairs = [t for t in p.get_values(lv).iteritems()]
        pairs = sorted(pairs)
        vlist = [y for (x,y) in pairs]
        # print 'solution = \n',vlist
        #for (x,y) in pairs:
        #    if y != 0:
        #        print '(x,y)=',x,y,' ; ',
        print 'now as a matrix\n'
        m = matrix(QQ, 8, 64, vlist)
        sage.plot.matrix_plot.matrix_plot(m).show()
    
    # print 'lv values = '
#     m = matrix(ZZ, 8, 64, lv.values())
#     print 'lv keys = ',
#     print lv.keys()
    
    # pprint.pprint(lv.values())
    # sage.plot.matrix_plot.matrix_plot(m).show()
    # return p    
            

print 'starting up'
vectors = list(itertools.product(range(2), repeat = 3))
print 'vectors = ', vectors
spread_indices = list(itertools.product(range(3), repeat = 5))
# print 'spread_indices = ', spread_indices
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
            c_lists[d].append(vectors[t+1])
        print 'c distribution = ',c_distr    
        p = generate_LP(c_lists)
        nsteps = nsteps + 1
    if nsteps > 1:
        break
    
︡0bdd64ff-8bd6-45f4-a190-43a4b1d8a3f7︡{"stdout":"starting up\n"}︡{"stdout":"vectors =  [(0, 0, 0), (0, 0, 1), (0, 1, 0), (0, 1, 1), (1, 0, 0), (1, 0, 1), (1, 1, 0), (1, 1, 1)]\n"}︡{"stdout":"flags = went over endings in  (0, 0, 0, 0, 0)  =  [(1, 2), (2, 1)]\nc distribution =  (0, 0, 0, 0, 0, 1, 2)\nclient_index,k (0, 0, 0) , 0\nclient_index,k (0, 0, 1) , 0\nclient_index,k (0, 1, 0) , 0\nclient_index,k (0, 1, 1) , 0\nclient_index,k (1, 0, 0) , 0\nclient_index,k (1, 0, 1) , 0\nclient_index,k (0, 0, 0) , 0\nclient_index,k"}︡{"stdout":" (0, 0, 1) , 0\nclient_index,k (0, 1, 0) , 0\nclient_index,k (0, 1, 1) , 0\nclient_index,k (1, 0, 0) , 0\nclient_index,k (1, 0, 1) , 0\nclient_index,k (0, 0, 0) , 0\nclient_index,k (0, 0, 1) , 0\nclient_index,k (0, 1, 0) , 0\nclient_index,k (0, 1, 1) , 0\nclient_index,k"}︡{"stdout":" (1, 0, 0) , 0\nclient_index,k (1, 0, 1) , 0\nclient_index,k (0, 0, 0) , 0\nclient_index,k (0, 0, 1) , 0\nclient_index,k (0, 1, 0) , 0\nclient_index,k (0, 1, 1) , 0\nclient_index,k (1, 0, 0) , 0\nclient_index,k (1, 0, 1) , 0\nclient_index,k (1, 1, 0) , 1\nclient_index,k"}︡{"stdout":" (1, 1, 0) , 1\nclient_index,k (1, 1, 0) , 1\nclient_index,k (1, 1, 0) , 1\nclient_index,k (1, 1, 1) , 2\nclient_index,k (1, 1, 1) , 2\nclient_index,k (1, 1, 1) , 2\nclient_index,k (1, 1, 1) , 2\nADDING T2 CONSTRAINTS\nrandom solution #  0\nThe solution is"}︡{"stdout":"\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_K3zLEc.svg","show":true,"text":null,"uuid":"98027bc2-a19d-4819-959f-2575d1f93c75"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 1\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_lvVhPi.svg","show":true,"text":null,"uuid":"8160e8a3-4b4f-4a5c-91d3-38283a77d29a"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 2\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_KO6ytX.svg","show":true,"text":null,"uuid":"7731c806-c3ed-4b4a-ad93-2b399e8a580d"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 3\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_ievrnX.svg","show":true,"text":null,"uuid":"5400703c-05e7-425d-b023-037a62e49b92"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 4\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_Kx0WXl.svg","show":true,"text":null,"uuid":"188a683d-7249-44d5-9639-ce5b18059a49"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 5\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_FNc12i.svg","show":true,"text":null,"uuid":"28eb870c-a61b-4ca5-93cd-de6f61f97f61"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 6\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_BTYGtQ.svg","show":true,"text":null,"uuid":"405ffb3a-726a-4670-aa83-a325d96bbb72"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 7\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_2SQKFF.svg","show":true,"text":null,"uuid":"596b0e83-f417-4f26-b56e-deb3f1602679"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 8\nThe solution is"}︡{"stdout":"\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_z8CmgT.svg","show":true,"text":null,"uuid":"0dbf1b18-641b-4eae-aee0-a4710392f22b"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 9\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_4yzogf.svg","show":true,"text":null,"uuid":"8cdb0c1b-4a8f-4d43-a56b-7cd13d2bc1af"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 10\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_GO9pqd.svg","show":true,"text":null,"uuid":"8436a3d1-cbf3-4fa6-8d7e-0fbff285a1ce"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 11\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_YJAIN9.svg","show":true,"text":null,"uuid":"05862d49-4045-4f2d-a27c-89a02dd38762"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 12\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_f_Vxye.svg","show":true,"text":null,"uuid":"5435ce95-e42d-4389-aea3-bc4dad364696"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 13\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_psdw47.svg","show":true,"text":null,"uuid":"2f310f7d-5680-4a1d-89c6-55e194e293f9"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 14\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp__CM0Qr.svg","show":true,"text":null,"uuid":"d4713de4-ff2e-4036-a58b-7bd012e6941c"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 15\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_8LXVNk.svg","show":true,"text":null,"uuid":"79878136-dddc-404b-b89d-4f69e367813f"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 16\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_2Ms2Jy.svg","show":true,"text":null,"uuid":"88ec66a1-31f9-4cb9-97ff-673358c9054e"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 17\nThe solution is"}︡{"stdout":"\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_wiHCYX.svg","show":true,"text":null,"uuid":"29483c0c-063b-4bc1-9043-4ff7fe36d74b"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 18\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_iXzSdk.svg","show":true,"text":null,"uuid":"0e4b6540-b40b-4c10-ba5e-fd7efeea4bf3"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 19\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_7MEWpd.svg","show":true,"text":null,"uuid":"c967dfa6-cceb-4548-9b72-155a0c92995b"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 20\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_FryDjr.svg","show":true,"text":null,"uuid":"6ddc0d12-eedd-457c-ab05-7a8e97c81a3e"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 21\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_23tfIg.svg","show":true,"text":null,"uuid":"c3064f55-7839-4f26-8ea3-5f868959c687"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 22\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_WIY0cK.svg","show":true,"text":null,"uuid":"53b70286-24db-4891-9632-ef716f77b509"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 23\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_86e5hI.svg","show":true,"text":null,"uuid":"97f6ab2a-db71-47d6-933b-598abd67c50c"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 24\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_185TTz.svg","show":true,"text":null,"uuid":"1f484266-b8ab-4ab3-90ee-ae25f1a08201"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 25\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_ChUnGn.svg","show":true,"text":null,"uuid":"471ec4a9-48a5-4274-a35c-3a4aed99501c"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 26\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_JFNHaT.svg","show":true,"text":null,"uuid":"581f8345-8788-402a-b236-64ed0c3b3449"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 27\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_5u_8bo.svg","show":true,"text":null,"uuid":"fea84f91-1eb7-43b0-9475-87017b45bd61"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 28\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_mYsdpt.svg","show":true,"text":null,"uuid":"eb99218a-13f4-428d-8471-4c74db0c69ed"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 29\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_eubxSX.svg","show":true,"text":null,"uuid":"82116fcb-62dd-4512-9179-4934170908c6"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 30\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_t7AT6O.svg","show":true,"text":null,"uuid":"aaf54d0c-f8eb-4f15-8c39-597a39dd34a8"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 31\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_J2ARCH.svg","show":true,"text":null,"uuid":"262430db-f7b8-498c-aa4b-d833b642e74a"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 32\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_RpjDMm.svg","show":true,"text":null,"uuid":"8f60e3e2-41bb-4341-a35a-81b4620a54a7"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 33\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_kTmcn7.svg","show":true,"text":null,"uuid":"922839bb-7ebd-4942-b680-3e16c640357c"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 34\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_cKrOCW.svg","show":true,"text":null,"uuid":"01deec6d-124e-42d6-b04b-4bfaa074d68a"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 35\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_b9SWrO.svg","show":true,"text":null,"uuid":"8250c4c7-3376-4c27-af03-e9172ffe1061"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 36\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_7iMphn.svg","show":true,"text":null,"uuid":"cf45410f-85c8-4018-84cf-a8fd83a2c0be"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 37\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_Rdw99H.svg","show":true,"text":null,"uuid":"27617e6a-643f-4a74-8137-5a653e083566"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 38\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_lfmcpu.svg","show":true,"text":null,"uuid":"61be177b-1635-4163-83bd-88fa7234c02f"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 39\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp__jNG4Z.svg","show":true,"text":null,"uuid":"a420f4d2-bbb8-4302-a459-d8dc3d1a4901"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 40\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_Xcrc9k.svg","show":true,"text":null,"uuid":"40d374ea-a666-4dbd-ab9e-211259242be8"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 41\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_vEhWYc.svg","show":true,"text":null,"uuid":"d822e1e7-7f01-415c-a82c-3f75a987c631"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 42\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_Rm7Yeo.svg","show":true,"text":null,"uuid":"ed2d1b50-ceae-4b95-a16f-ab7de9eddab6"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 43\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_MIZtRp.svg","show":true,"text":null,"uuid":"fe998bd3-bf00-4cdb-85c4-5844c3dc09e5"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 44\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_mEELc7.svg","show":true,"text":null,"uuid":"4e455378-6c87-4a89-8c87-bb6796460d3a"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 45\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp__UvPx8.svg","show":true,"text":null,"uuid":"44656a80-ef8c-4b68-b76f-ab2e52d12483"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 46\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_sTH3mE.svg","show":true,"text":null,"uuid":"a6e1ddaa-fedf-448d-b943-8d82e342562f"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 47\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_aF5hzL.svg","show":true,"text":null,"uuid":"d2126366-cbd0-4031-9d0c-ee65d820c34f"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 48\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_FKi0f5.svg","show":true,"text":null,"uuid":"ffa1b799-9497-4927-93c1-611c1fe85a7e"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 49\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_Zym3Cz.svg","show":true,"text":null,"uuid":"c3971ee0-934c-45c1-9f61-6377ed1eb1dd"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 50\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_EPkqtL.svg","show":true,"text":null,"uuid":"6590f203-3336-483b-af12-d5d1e6118251"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 51\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_q5a34d.svg","show":true,"text":null,"uuid":"4138130a-606d-4543-a487-a178bf477331"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 52\nThe solution is\nnow as a matrix\n\n"}︡{"file":{"filename":"/home/user/.sage/temp/project-9005d034-5886-4217-bd5e-49c40dc11971/648/tmp_PZyz6r.svg","show":true,"text":null,"uuid":"f1a9813b-7136-4548-bc86-5add8f7eb5d3"},"once":false}︡{"stdout":"random solution # "}︡{"stdout":" 53\nThe solution is\nnow as a matrix\n\n"}︡
︠81c75631-c8b5-42e4-aa08-f4d68c56274cs︠
    
p = MixedIntegerLinearProgram()
v = p.new_variable(real=True, nonnegative=True)
p.solve()
x, y, z = v['x'], v['y'], v['z']
type(2*x <= 0)
v = p.get_values(v)
print v.values()
print v.keys()
x=1
s=55
print x/s
︡f62d3342-0386-45b6-be86-7e2b8f37daa1︡{"stdout":"0.0\n"}︡{"stdout":"<type 'sage.numerical.linear_functions.LinearConstraint'>\n"}︡{"stdout":"[0.0, 0.0, 0.0]\n"}︡{"stdout":"['y', 'x', 'z']\n"}︡{"stdout":"1/55\n"}︡{"done":true}︡
︠8a557a48-4e83-4a9c-90d6-5d573a2a49b4︠

︠7dcf55ec-c018-4009-8544-a64ce0b7afd1︠










