```@meta
CurrentModule = AbstractAlgebra
DocTestSetup = quote
    using AbstractAlgebra
end
```

# Generic residue rings

AbstractAlgebra.jl provides a module, implemented in `src/generic/Residue.jl` for
generic residue rings over any Euclidean domain (in practice most of the functionality
is provided for GCD domains that provide a meaningful GCD function) belonging to the
AbstractAlgebra.jl abstract type hierarchy.

As well as implementing the Residue Ring interface a number of generic algorithms are
implemented for residue rings. We describe this generic functionality below.

All of the generic functionality is part of a submodule of AbstractAlgebra called
`Generic`. This is exported by default so that it is not necessary to qualify the
function names with the submodule name.

## Types and parent objects

Residues implemented using the AbstractAlgebra generics have type `Generic.Res{T}`
or in the case of residue rings that are known to be fields, `Generic.ResF{T}`, where
`T` is the type of elements of the base ring. See the file `src/generic/GenericTypes.jl`
for details.

Parent objects of residue ring elements have type `Generic.ResRing{T}` and those of
residue fields have type `GenericResField{T}`.

The defining modulus of the residue ring is stored in the parent object.

The residue element types belong to the abstract type `AbstractAlgebra.ResElem{T}`
or `AbstractAlgebra.ResFieldElem{T}` in the case of residue fields, and the residue
ring types belong to the abstract type `AbstractAlgebra.ResRing{T}` or
`AbstractAlgebra.ResField{T}` respectively. This enables one to write generic functions
that can accept any AbstractAlgebra residue type.

Note that both the generic residue ring type `Generic.ResRing{T}` and the abstract
type it belongs to, `AbstractAlgebra.ResRing{T}` are both called `ResRing`, and
similarly for the residue field types. In each case, the  former is a (parameterised)
concrete type for a residue ring over a given base ring whose elements have type `T`.
The latter is an abstract type representing all residue ring types in
AbstractAlgebra.jl, whether generic or very specialised (e.g. supplied by a C library).

## Residue ring constructors

In order to construct residues in AbstractAlgebra.jl, one must first construct the
residue ring itself. This is accomplished with one of the following constructors.

```julia
ResidueRing(R::AbstractAlgebra.Ring, m::AbstractAlgebra.RingElem; cached::Bool = true)
```
```julia
ResidueField(R::AbstractAlgebra.Ring, m::AbstractAlgebra.RingElem; cached::Bool = true)
```

Given a base ring `R` and residue $m$ contained in this ring, return the parent object
of the residue ring $R/(m)$. By default the parent object `S` will depend only on `R`
and `m` and will be cached. Setting the optional argument `cached` to `false` will
prevent the parent object `S` from being cached.

The `ResidueField` constructor does the same thing as the `ResidueRing` constructor,
but the resulting object has type belonging to `Field` rather than `Ring`, so it can
be used anywhere a field is expected in AbstractAlgebra.jl. No check is made for
maximality of the ideal generated by $m$.

Here are some examples of creating residue rings and making use of the
resulting parent objects to coerce various elements into the residue ring.

**Examples**

```jldoctest
julia> R, x = PolynomialRing(QQ, "x")
(Univariate Polynomial Ring in x over Rationals, x)

julia> S = ResidueRing(R, x^3 + 3x + 1)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> f = S()
0

julia> g = S(123)
123

julia> h = S(BigInt(1234))
1234

julia> k = S(x + 1)
x + 1

```

All of the examples here are generic residue rings, but specialised implementations
of residue rings provided by external modules will also usually provide a
`ResidueRing` constructor to allow creation of their residue rings.

## Basic ring functionality

Residue rings in AbstractAlgebra.jl implement the full Ring interface. Of course
the entire Residue Ring interface is also implemented.

We give some examples of such functionality.

**Examples**

```jldoctest
julia> R, x = PolynomialRing(QQ, "x")
(Univariate Polynomial Ring in x over Rationals, x)

julia> S = ResidueRing(R, x^3 + 3x + 1)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> f = S(x + 1)
x + 1

julia> h = zero(S)
0

julia> k = one(S)
1

julia> isone(k)
true

julia> iszero(f)
false

julia> m = modulus(S)
x^3 + 3*x + 1

julia> U = base_ring(S)
Univariate Polynomial Ring in x over Rationals

julia> V = base_ring(f)
Univariate Polynomial Ring in x over Rationals

julia> T = parent(f)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> f == deepcopy(f)
true

```

## Residue ring functionality provided by AbstractAlgebra.jl

The functionality listed below is automatically provided by AbstractAlgebra.jl for
any residue ring module that implements the full Residue Ring interface.
This includes AbstractAlgebra.jl's own generic residue rings.

But if a C library provides all the functionality documented in the Residue Ring
interface, then all the functions described here will also be automatically supplied by
AbstractAlgebra.jl for that residue ring type.

Of course, modules are free to provide specific implementations of the functions
described here, that override the generic implementation.

### Basic functionality

```@docs
modulus(::AbstractAlgebra.ResElem)
```

**Examples**

```jldoctest
julia> R, x = PolynomialRing(QQ, "x")
(Univariate Polynomial Ring in x over Rationals, x)

julia> S = ResidueRing(R, x^3 + 3x + 1)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> r = S(x + 1)
x + 1

julia> a = modulus(S)
x^3 + 3*x + 1

julia> isunit(r)
true

```

### Inversion

```@docs
Base.inv(::AbstractAlgebra.ResElem)
```

**Examples**

```jldoctest
julia> R, x = PolynomialRing(QQ, "x")
(Univariate Polynomial Ring in x over Rationals, x)

julia> S = ResidueRing(R, x^3 + 3x + 1)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> f = S(x + 1)
x + 1

julia> g = inv(f)
1//3*x^2 - 1//3*x + 4//3

```

### Greatest common divisor

```@docs
gcd{T <: RingElem}(::ResElem{T}, ::ResElem{T})
```

**Examples**

```jldoctest
julia> R, x = PolynomialRing(QQ, "x")
(Univariate Polynomial Ring in x over Rationals, x)

julia> S = ResidueRing(R, x^3 + 3x + 1)
Residue ring of Univariate Polynomial Ring in x over Rationals modulo x^3 + 3*x + 1

julia> f = S(x + 1)
x + 1

julia> g = S(x^2 + 2x + 1)
x^2 + 2*x + 1

julia> h = gcd(f, g)
1

```

### Square Root

```@docs
issquare{T <: Integer}(::ResFieldElem{T})
```

```@docs
Base.sqrt{T <: Integer}(::ResFieldElem{T})
```

**Examples**

```julia
julia> R = ResidueField(ZZ, 733)
Residue field of Integers modulo 733

julia> a = R(86)
86

julia> issquare(a)
true

julia> sqrt(a)
532
```
