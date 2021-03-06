*! version 2.0.3  01dec2020  Ben Jann
version 9.2
mata:

real matrix mm_quantile(real matrix X, | real colvector w,
    real matrix P, real scalar d, real scalar fw)
{
    real colvector o
    pointer (real matrix) scalar XX, ww
    
    if (args()<2) w = 1
    if (args()<3) P = (0, .25, .50, .75, 1)'
    if (args()<4) d = 2
    if (args()<5) fw = 0
    if (!anyof(0::9, d)) {
        display("{err}{it:def} must be an integer in [0,9]")
        _error(3300)
    }
    if (missing(X) | missing(w)) _error(3351)
    if (any(w:<0)) {
        display("{err}{it:w} must not be negative")
        _error(3300)
    }
    // drop zero frequency observations (i.e. observations for which w = 0) and
    // determine whether weights can be ignored
    XX = &X; ww = &w
    if (rows(w)!=1) {
        if (rows(w)!=rows(X)) _error(3200)
        if (anyof(w,0)) {
            o = select(1::rows(w), w)
            if (cols(o)==0) o = J(0,1,.) // select() may return 0x0
            XX = &(X[o,])
            ww = &(w[o])
        }
        // weights can be ignored if constant and d = 1 or 2
        if ((d==1 | d==2) & rows(*ww)) { // (*ww may be void)
            if (allof(*ww, (*ww)[1])) ww = &1
        }
        // weights can be ignored if w = 1 for all observations
        else if (allof(*ww,1)) ww = &1
    }
    else if (w==0) {
        XX = &(J(0,cols(X),.))
        ww = &(J(0,1,.))
    }
    // compute quantiles
    if (cols(X)==1 & cols(P)!=1 & rows(P)==1)
        return(_mm_quantile_sort(*XX, *ww, P', d, fw)')
    if (cols(X)!=1 & cols(P)!=1 & cols(X)!=cols(P)) _error(3200)
    return(_mm_quantile_sort(*XX, *ww, P, d, fw))
}

real matrix _mm_quantile_sort(real matrix X, real colvector w,
    real matrix P, real scalar d, real scalar fw)
{
    real scalar    i, c, c1, c2
    real colvector p, sX, sw, pP, sP
    real matrix    Q

    c1 = cols(X); c2 = cols(P)
    c = max((c1,c2))
    Q = J(rows(P), c, .)
    if (c1==c2) {
        if (w==1) {
            for (i=c; i; i--) {
                Q[,i] = _mm_quantile_d(sort(X[,i],1), editmissing(P[,i],1), d)
            }
            return(Q)
        }
        if (rows(w)==1) {
            for (i=c; i; i--) {
                pP = order(P[,i],1); sP = P[pP,i]
                Q[pP,i] = _mm_quantile_w(sort(X[,i],1), w, sP, d, fw)
            }
            return(Q)
        }
        for (i=c; i; i--) {
            p = order((X[,i],w),(1,2)); sX = X[p,i]; sw = w[p]
            pP = order(P[,i],1); sP = P[pP,i]
            Q[pP,i] = _mm_quantile_w(sX, sw, sP, d, fw)
        }
        return(Q)
    }
    if (c1==1) {
        if (w==1) {
            sX = sort(X,1)
            for (i=c; i; i--) {
                Q[,i] = _mm_quantile_d(sX, editmissing(P[,i],1), d)
            }
            return(Q)
        }
        if (rows(w)==1) {
            sX = sort(X,1)
            for (i=c; i; i--) {
                pP = order(P[,i],1); sP = P[pP,i]
                Q[pP,i] = _mm_quantile_w(sX, w, sP, d, fw)
            }
            return(Q)
        }
        p = order((X,w),(1,2)); sX = X[p]; sw = w[p]
        for (i=c; i; i--) {
            pP = order(P[,i],1); sP = P[pP,i]
            Q[pP,i] = _mm_quantile_w(sX, sw, sP, d, fw)
        }
        return(Q)
    }
    if (c2==1) {
        if (w==1) {
            sP = editmissing(P,1)
            for (i=c; i; i--) {
                Q[,i] = _mm_quantile_d(sort(X[,i],1), sP, d)
            }
            return(Q)
        }
        if (rows(w)==1) {
            pP = order(P,1); sP = P[pP]
            for (i=c; i; i--) {
                Q[pP,i] = _mm_quantile_w(sort(X[,i],1), w, sP, d, fw)
            }
            return(Q)
        }
        pP = order(P,1); sP = P[pP]
        for (i=c; i; i--) {
            p = order((X[,i],w),(1,2)); sX = X[p,i]; sw = w[p]
            Q[pP,i] = _mm_quantile_w(sX, sw, sP, d, fw)
        }
        return(Q)
    }
    _error(3200)
}

real matrix _mm_quantile(real colvector X, | real colvector w, 
    real matrix P, real scalar d, real scalar fw)
{   // X assumed sorted and non-missing
    // w assumed non-negative and non-missing
    real scalar    i
    real colvector o
    real matrix    Q
    pointer (real matrix) scalar XX, ww
    
    if (args()<2) w = 1
    if (args()<3) P = (0, .25, .50, .75, 1)'
    if (args()<4) d = 2
    if (args()<5) fw = 0
    // drop zero frequency observations (i.e. observations for which w = 0) and
    // determine whether weights can be ignored
    XX = &X; ww = &w
    if (rows(w)!=1) {
        if (rows(w)!=rows(X)) _error(3200)
        if (anyof(w,0)) {
            o = select(1::rows(w), w)
            if (cols(o)==0) o = J(0,1,.) // select() may return 0x0
            XX = &(X[o,])
            ww = &(w[o])
        }
        // weights can be ignored if constant and d < 3
        if (d<3 & rows(*ww)) { // (*ww may be void)
            if (allof(*ww, (*ww)[1])) ww = &1
        }
        // weights can be ignored if w = 1 for all observations
        else if (allof(*ww,1)) ww = &1
    }
    else if (w==0) {
        XX = &(J(0,1,.))
        ww = &(J(0,1,.))
    }
    // compute weighted quantiles: requires sorted p
    if (*ww!=1) {  // not rows(*ww)!=1 !
        if (rows(P)==1) {
            o = order(P',1)
            Q = o // just to dimension q
            Q[o] = _mm_quantile_w(*XX, *ww, P[o]', d, fw)
            return(Q')
        }
        Q = J(rows(P), cols(P), .)
        for (i=cols(P); i; i--) {
            o = order(P[,i],1)
            Q[o,i] = _mm_quantile_w(*XX, *ww, P[o,i], d, fw)
        }
        return(Q)
    }
    // compute unweighted quantiles
    if (rows(P)==1) return(_mm_quantile_d(*XX, editmissing(P',1), d)')
    Q = J(rows(P), cols(P), .)
    for (i=cols(P); i; i--) Q[,i] = _mm_quantile_d(*XX, editmissing(P[,i],1), d)
    return(Q)
}

real colvector _mm_quantile_d(real colvector X, real colvector p, real scalar d)
{   // X assumed sorted and non-missing
    // p assumed nonmissing
    real scalar     n, eps
    real colvector  pn, j, j1, h

    n = rows(X)
    if ((rows(p)*n)==0) return(J(rows(p), 1, .)) // no obs or rows(p)==0
    if (n==1)           return(J(rows(p), 1, X)) // only one obs
    if      (d==0) pn = p :* n
    else if (d==1) pn = p :* n
    else if (d==2) pn = p :* n
    else if (d==3) pn = p :* n :- .5
                                                // pn = a + p*(n + 1 - a - b)
    else if (d==4) pn = p :* n                  //      a = 0, b = 1
    else if (d==5) pn = p :* n :+ .5            //      a = b = 0
    else if (d==6) pn = p :* (n + 1)            //      a = b = 0 
    else if (d==7) pn = 1 :+ p :* (n - 1)       //      a = b = 1
    else if (d==8) pn = 1/3 :+ p :* (n + 1/3)   //      a = b = 1/3
    else if (d==9) pn = 3/8 :+ p :* (n + 1/4)   //      a = b = 3/8
    else {
        display("{err}{it:def} must be an integer in [0,9]")
        _error(3300)
    }
    if (d==0) return(X[mm_clip(floor(pn):+1, 1, n)])
    if (d==1) return(X[mm_clip(ceil(pn), 1, n)])
    if (d<=3) {
        j = floor(pn)
        if (d==2) h = ((pn:>j) :+ 1) / 2
        else      h = (pn:>j) :| mod(j,2)
    }
    else {
        eps = 4 * epsilon(1) // handle rounding error as in R's quantile()
        j = floor(pn :+ eps)
        h = pn - j
        h = h :* (abs(h):>=eps)
    }
    j1 = mm_clip(j:+1, 1, n)
    _mm_clip(j, 1, n)
    return((1:-h) :* X[j] :+ h :* X[j1])
}

real colvector _mm_quantile_w(real colvector X, real colvector w, real colvector p, 
    real scalar d, real scalar fw)
{   // X assumed sorted and non-missing
    // w assumed non-missing and *strictly* positive
    // p assumed sorted
    real scalar n
    real matrix W
    
    n = rows(X)
    if (n==0)       return(J(rows(p), 1, .))
    if (n==1)       return(J(rows(p), 1, X))
    if (rows(w)==0) return(J(rows(p), 1, .))
    // frequency weights or d<3 (for which type of weights is irrelevant)
    if (fw | d<3) {
        W = _mm_ecdf2(X, w, 0, 1) // W = (uniq X, runningsum(w))
        if (d==0) return(_mm_quantile_w_0(W[,1], W[,2], p))
        if (d==1) return(_mm_quantile_w_1(W[,1], W[,2], p))
        if (d==2) return(_mm_quantile_w_2(W[,1], W[,2], p))
        if (d==3) return(_mm_quantile_w_3(W[,1], W[,2], p))
        if (d==4) return(_mm_quantile_w_d(W[,1], W[,2], p,   0,   0))
        if (d==5) return(_mm_quantile_w_d(W[,1], W[,2], p,  .5,   0))
        if (d==6) return(_mm_quantile_w_d(W[,1], W[,2], p,   0,   1))
        if (d==7) return(_mm_quantile_w_d(W[,1], W[,2], p,   1,  -1))
        if (d==8) return(_mm_quantile_w_d(W[,1], W[,2], p, 1/3, 1/3))
        if (d==9) return(_mm_quantile_w_d(W[,1], W[,2], p, 3/8, 1/4))
        display("{err}{it:def} must be an integer in [0,9]")
        _error(3300)
    }
    // other cases
    if (rows(w)==1) W = (1::n) * w
    else {
        W = mm_colrunsum(w, 1, 1) // use quad precision
        if (W[n]>=.) W = J(n,1,.)
    }
    if (d==3) return(_mm_quantile_w_3b(X, W, p))
    else {
        if      (d==4) W =  W             /  W[n]
        else if (d==5) W = (W :- w/2)     /  W[n]
        else if (d==6) W =  W             / (W[n] + W[n]/n)
        else if (d==7) W = (W :- w)       / (W[n] - W[n]/n)
        else if (d==8) W = (W :- w/3)     / (W[n] + W[n]/(3*n))
        else if (d==9) W = (W :- (3/8)*w) / (W[n] + W[n]/(4*n))
        else {
            display("{err}{it:def} must be an integer in [0,9]")
            _error(3300)
        }
        return(mm_fastipolate(W, X, p, 1))
    }
}

real colvector _mm_quantile_w_0(real colvector x, real colvector W, real colvector p)
{
    real scalar    i, j, pi
    real colvector P, q
    
    j = rows(W) 
    P = p * W[j]
    i = rows(p)
    q = J(i,1,.)
    for (; i; i--) {
        pi = P[i]
        for (; j>1; j--) {
            if (W[j-1]<=pi) break
        }
        q[i] = x[j]
    }
    return(q)
}

real colvector _mm_quantile_w_1(real colvector x, real colvector W, real colvector p)
{
    real scalar    i, j, pi
    real colvector P, q
    
    j = rows(W) 
    P = p * W[j]
    i = rows(p)
    q = J(i,1,.)
    for (; i; i--) {
        pi = P[i]
        for (; j>1; j--) {
            if (W[j-1]<pi) break
        }
        q[i] = x[j]
    }
    return(q)
}

real colvector _mm_quantile_w_2(real colvector x, real colvector W, real colvector p)
{
    real scalar    i, j, r, pi
    real colvector P, q
    
    j = r = rows(W) 
    P = p * W[j]
    i = rows(p)
    q = J(i,1,.)
    for (; i; i--) {
        pi = P[i]
        for (; j>1; j--) {
            if (W[j-1]<pi) break
        }
        if (W[j]==pi) {
            if (j==r) q[i] = x[j]
            else      q[i] = (x[j] + x[j+1])/2
        }
        else q[i] = x[j]
    }
    return(q)
}

real colvector _mm_quantile_w_3(real colvector x, real colvector W, real colvector p)
{
    real scalar    i, j, pi, lo, up, d0, d1
    real colvector P, q
    
    j = rows(W)
    P = p * W[j]
    i = rows(p)
    q = J(i,1,.)
    for (; i; i--) {
        pi = P[i]
        // find j such that W[j-1] < pi <= W[j]
        for (; j>1; j--) {
            if (W[j-1]<pi) break
        }
        // reached bottom
        if (j==1) { 
            q[|1\i|] = J(i,1, x[1])
            break
        }
        // if pi is larger than or equal to the next integer after W[j-1],
        // then use the upper x-value; decide between lower and upper x-value
        // only if pi is between W[j-1] and next integer
        lo = W[j-1]
        up = floor(lo) + 1
        if (pi>=up) q[i] = x[j]
        else {
            // set upper boundary to minimum between W[j] and next integer
            // after W[j-1]
            up = min( (W[j], up) )
            // obtain distances between pi and boundaries
            d0 = pi - lo
            d1 = up - pi
            // case 1: pi closer to upper boundary
            if (d1<d0) q[i] = x[j]
            // case 2: pi closer to lower boundary
            else if (d0<d1) q[i] = x[j-1]
            // case 3: equal distance
            else {
                // use x-value from lower boundary if lower boundary is integer 
                // and even; else use x-value from upper boundary; this is an
                // arbitrary decision
                if (!mod(lo,2)) q[i] = x[j-1]
                else            q[i] = x[j]
            }
        }
    }
    return(q)
}

real colvector _mm_quantile_w_3b(real colvector x, real colvector W, real colvector p)
{
    real scalar    i, j, pi, d0, d1
    real colvector P, q
    
    j = rows(W)
    P = p * W[j]
    i = rows(p)
    q = J(i,1,.)
    for (; i; i--) {
        pi = P[i]
        for (; j>1; j--) {
            if (W[j-1]<pi) break
        }
        // reached bottom
        if (j==1) { 
            q[|1\i|] = J(i,1, x[1])
            break
        }
        // obtain distances
        d0 = pi - W[j-1]
        d1 = W[j] - pi
        // case 1: pi closer to upper boundary
        if (d1<d0) q[i] = x[j]
        // case 2: pi closer to lower boundary
        else if (d0<d1) q[i] = x[j-1]
        // case 3: equal distance
        else {
            // use x-value from upper boundary if index of upper boundary is
            // even; else use x-value from lower boundary
            if (!mod(j,2)) q[i] = x[j]
            else           q[i] = x[j-1]
        }
    }
    return(q)
}

real colvector _mm_quantile_w_d(real colvector x, real colvector W, 
    real colvector p, real scalar a, real scalar b)
{
    real scalar    i, j, pi, lo, up, h, T
    real colvector q, pk
    
    j  = rows(W)
    T  = W[j] + b
    pk = (W :- a) / T
    i  = rows(p)
    q  = J(i,1,.)
    for (; i; i--) {
        pi = p[i]
        // find j such that pk[j-1] < pi <= pk[j]
        for (; j>1; j--) {
            if (pk[j-1]<pi) break
        }
        // reached bottom
        if (j==1) {
            q[|1\i|] = J(i,1, x[1])
            break
        }
        // if pi is larger than or equal to pk of next integer after W[j-1],
        // then use the upper x-value; interpolate only if pi is between 
        // pk[j-1] and pk of next integer
        up = (floor(W[j-1]) + 1 - a) / T
        if (pi>=up) q[i] = x[j]
        else {
            lo   = pk[j-1]
            up   = min( (pk[j], up) )
            h    = (pi - lo) / (up - lo)
            q[i] = (1-h) * x[j-1] + h * x[j]
        }
    }
    return(q)
}


end
