# PetRBF
Many applications in computational science need to approximate a function based on finite data. When the data are in
a certain sense “scattered” in their domain, one very powerful technique is radial basis function (RBF) interpolation.
For many years, the wide applicability of RBF interpolation was hindered by its numerical difficulty and expense.
Indeed, in their mathematical expression, RBF methods produce an ill-conditioned linear system, for which a direct
solution becomes prohibitive for more than a few thousand data points.

We have developed a parallel algorithm for RBF interpolation that exhibits O(N) complexity, requires O(N) storage,
and scales excellently up to a thousand processes. The algorithm uses the GMRES iterative solver with a restricted
additive Schwarz method (RASM) as a preconditioner and a fast matrix-vector algorithm. Previous fast RBF methods
— achieving at most O(N log N) complexity — were developed using multiquadric and polyharmonic basis functions. In
contrast, the present method uses Gaussians with a small variance. The fast decay of the Gaussian basis function
allows rapid convergence of the iterative solver even when the subdomains in the RASM are very small. The method was
implemented in parallel using the PETSc library (developer version). Numerical experiments demonstrate its capability
in problems of RBF interpolation with more than 50 million data points, timing at 106 seconds (19 iterations for an
error tolerance of 10e−15) on 1024 processors of a Blue Gene/L (700 MHz PowerPC processors).

See the paper [PetRBF--A parallel O(N) algorithm for radial basis function interpolation](http://arxiv.org/abs/0909.5413) by Rio Yokota, L A Barba, Matthew G Knepley, and visit [The Barba Group page](http://lorenabarba.com/) for more information. A [summary of this project](http://www.bu.edu/tech/support/research/visualization/gallery/petrbf/) is also available among the Boston University research computing briefs.

> We distribute this code under the MIT License, giving potential users the greatest freedom possible. We do, however, request fellow scientists that if they use our codes in research, they kindly include us in the acknowledgement of their papers. We do not request gratuitous citations; only cite our articles if you deem it warranted.



# Installation

I've found two older versions of PETSc that seem to work with PetBRF

## PETSc v3.5

 Compile PETSc v3.5, and modify the following line from both `2d/rbf_interpolation.cxx` and `3d/rbf_interpolation.cxx`:
```c++
ierr = KSPSetOperators(ksp,M,P,DIFFERENT_NONZERO_PATTERN);CHKERRQ(ierr);
```
to
```c++
ierr = KSPSetOperators(ksp,M,P);CHKERRQ(ierr);
```
## PETSc v3.4.5
No modifications to PetRBF are required.


I haven't done extensive testing, but `make cpu` compiles and tests with no problem.

ps: I tried compiling PetRBF with both PETSc v3.4 and v3.3 and none of them worked. Only v3.5 with that fix does it, and v3.4.5.
ps2: To build an older version of PETSc, clone the PETSc repo (`git clone https://bitbucket.org/petsc/petsc.git`), checkout the version (*e.g.,* `git checkout v3.5`), run the configure script (`./configure`) and follow its instructions. When compiling PetRBF you'll have to define PETSC_DIR pointing to the build of PETSc.
