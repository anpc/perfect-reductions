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
    p = Polyhedron(ieqs = constraint_list)
    for q in p.Vrepresentation():
        print(q)
   

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
        generate_LP(c_lists)
        nsteps = nsteps + 1
    if nsteps > 10:
        break
