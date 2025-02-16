###############################################################################
#
#   Fraction.jl : generic fraction fields
#
###############################################################################

export FractionField

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

parent_type(::Type{Frac{T}}) where T <: RingElem = FracField{T}

elem_type(::Type{FracField{T}}) where {T <: RingElem} = Frac{T}

base_ring(a::AbstractAlgebra.FracField{T}) where T <: RingElem = a.base_ring::parent_type(T)

base_ring(a::AbstractAlgebra.FracElem) = base_ring(parent(a))

parent(a::AbstractAlgebra.FracElem) = a.parent

function isdomain_type(::Type{T}) where {S <: RingElement, T <: AbstractAlgebra.FracElem{S}}
   return isdomain_type(S)
end

function isexact_type(a::Type{T}) where {S <: RingElement, T <: AbstractAlgebra.FracElem{S}}
   return isexact_type(S)
end

@doc Markdown.doc"""
    characteristic(R::AbstractAlgebra.FracField{T}) where T <: RingElem

Return the characteristic of the given field.
"""
function characteristic(R::AbstractAlgebra.FracField{T}) where T <: RingElem
   return characteristic(base_ring(R))
end

function check_parent(a::AbstractAlgebra.FracElem, b::AbstractAlgebra.FracElem, throw::Bool = true)
   fl = parent(a) != parent(b)
   fl && throw && error("Incompatible rings in fraction field operation")
   return !fl
end

###############################################################################
#
#   Constructors
#
###############################################################################

function //(x::T, y::T) where {T <: RingElem}
   iszero(y) && throw(DivideError())
   g = gcd(x, y)
   z = Frac{T}(divexact(x, g), divexact(y, g))
   try
      z.parent = FracDict[R]
   catch
      z.parent = FractionField(parent(x))
   end
   return z
end

//(x::T, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem} = parent(y)(x)//y

//(x::AbstractAlgebra.FracElem{T}, y::T) where {T <: RingElem} = x//parent(x)(y)

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function Base.hash(a::AbstractAlgebra.FracElem, h::UInt)
   b = 0x8a30b0d963237dd5%UInt
   # We canonicalise before hashing
   return xor(b, hash(numerator(a, true), h), hash(denominator(a, true), h), h)
end

function Base.numerator(a::Frac, canonicalise::Bool=true)
   if canonicalise
      u = canonical_unit(a.den)
      return divexact(a.num, u)
   else
      return a.num
   end
end

function Base.denominator(a::Frac, canonicalise::Bool=true)
   if canonicalise
      u = canonical_unit(a.den)
      return divexact(a.den, u)
   else
      return a.den
   end
end

# Fall back method for all other fraction types in system
function Base.numerator(a::AbstractAlgebra.FracElem, canonicalise::Bool=true)
   return Base.numerator(a) # all other types ignore canonicalise
end

# Fall back method for all other fraction types in system
function Base.denominator(a::AbstractAlgebra.FracElem, canonicalise::Bool=true)
   return Base.denominator(a) # all other types ignore canonicalise
end

zero(R::AbstractAlgebra.FracField) = R(0)

one(R::AbstractAlgebra.FracField) = R(1)

iszero(a::AbstractAlgebra.FracElem) = iszero(numerator(a, false))

isone(a::AbstractAlgebra.FracElem) = numerator(a, false) == denominator(a, false)

isunit(a::AbstractAlgebra.FracElem) = !iszero(numerator(a, false))

function deepcopy_internal(a::Frac{T}, dict::IdDict) where {T <: RingElem}
   v = Frac{T}(deepcopy(numerator(a, false)), deepcopy(denominator(a, false)))
   v.parent = parent(a)
   return v
end

###############################################################################
#
#   Canonicalisation
#
###############################################################################

canonical_unit(a::AbstractAlgebra.FracElem) = a

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function AbstractAlgebra.expressify(a::FracElem; context = nothing)
    n = numerator(a, true)
    d = denominator(a, true)
    if isone(d)
        return expressify(n)
    else
        return Expr(:call, ://, expressify(n), expressify(d))
    end
end

function show(io::IO, ::MIME"text/plain", a::FracElem)
  print(io, AbstractAlgebra.obj_to_string(a, context = io))
end

function show(io::IO, a::FracElem)
  print(io, AbstractAlgebra.obj_to_string(a, context = io))
end

function show(io::IO, a::AbstractAlgebra.FracField)
   print(IOContext(io, :compact => true), "Fraction field of ", base_ring(a))
end

###############################################################################
#
#   Unary operators
#
###############################################################################

function -(a::AbstractAlgebra.FracElem)
   return parent(a)(-numerator(a, false), deepcopy(denominator(a, false)))
end

###############################################################################
#
#   Binary operators
#
###############################################################################

function +(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   check_parent(a, b)
   d1 = denominator(a, false)
   d2 = denominator(b, false)
   n1 = numerator(a, false)
   n2 = numerator(b, false)
   if d1 == d2
      rnum = n1 + n2
      if isone(d1)
         rden = deepcopy(d1)
      else
         gd = gcd(rnum, d1)
         if isone(gd)
            rden = deepcopy(d1)
         else
            rnum = divexact(rnum, gd)
            rden = divexact(d1, gd)
         end
      end
   elseif isone(d1)
      rnum = n1*d2 + n2
      rden = deepcopy(d2)
   elseif isone(d2)
      rnum = n1 + n2*d1
      rden = deepcopy(d1)
   else
      gd = gcd(d1, d2)
      if isone(gd)
         rnum = n1*d2 + n2*d1
         rden = d1*d2
      else
         q1 = divexact(d1, gd)
         q2 = divexact(d2, gd)
         rnum = q1*n2 + q2*n1
         t = gcd(rnum, gd)
         if isone(t)
            rden = q2*d1
         else
            rnum = divexact(rnum, t)
            gd = divexact(d1, t)
            rden = gd*q2
         end
      end
   end
   return parent(a)(rnum, rden)
end

function -(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   check_parent(a, b)
   d1 = denominator(a, false)
   d2 = denominator(b, false)
   n1 = numerator(a, false)
   n2 = numerator(b, false)
   if d1 == d2
      rnum = n1 - n2
      if isone(d1)
         rden = deepcopy(d1)
      else
         gd = gcd(rnum, d1)
         if isone(gd)
            rden = deepcopy(d1)
         else
            rnum = divexact(rnum, gd)
            rden = divexact(d1, gd)
         end
      end
   elseif isone(d1)
      rnum = n1*d2 - n2
      rden = deepcopy(d2)
   elseif isone(d2)
      rnum = n1 - n2*d1
      rden = deepcopy(d1)
   else
      gd = gcd(d1, d2)
      if isone(gd)
         rnum = n1*d2 - n2*d1
         rden = d1*d2
      else
         q1 = divexact(d1, gd)
         q2 = divexact(d2, gd)
         rnum = q2*n1 - q1*n2
         t = gcd(rnum, gd)
         if isone(t)
            rden = q2*d1
         else
            rnum = divexact(rnum, t)
            gd = divexact(d1, t)
            rden = gd*q2
         end
      end
   end
   return parent(a)(rnum, rden)
end

function *(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   check_parent(a, b)
   n1 = numerator(a, false)
   d2 = denominator(b, false)
   n2 = numerator(b, false)
   d1 = denominator(a, false)
   if d1 == d2
      n = n1*n2
      d = d1*d2
   elseif isone(d1)
      gd = gcd(n1, d2)
      if isone(gd)
         n = n1*n2
         d = deepcopy(d2)
      else
         n = divexact(n1, gd)*n2
         d = divexact(d2, gd)
      end
   elseif isone(d2)
      gd = gcd(n2, d1)
      if isone(gd)
         n = n2*n1
         d = deepcopy(d1)
      else
         n = divexact(n2, gd)*n1
         d = divexact(d1, gd)
      end
   else
      g1 = gcd(n1, d2)
      g2 = gcd(n2, d1)
      if !isone(g1)
         n1 = divexact(n1, g1)
         d2 = divexact(d2, g1)
      end
      if !isone(g2)
         n2 = divexact(n2, g2)
         d1 = divexact(d1, g2)
      end
      n = n1*n2
      d = d1*d2
   end
   return parent(a)(n, d)
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function *(a::AbstractAlgebra.FracElem, b::Union{Integer, Rational, AbstractFloat})
   c = base_ring(a)(b)
   g = gcd(denominator(a, false), c)
   n = numerator(a, false)*divexact(c, g)
   d = divexact(denominator(a, false), g)
   return parent(a)(n, d)
end

function *(a::Union{Integer, Rational, AbstractFloat}, b::AbstractAlgebra.FracElem)
   c = base_ring(b)(a)
   g = gcd(denominator(b, false), c)
   n = numerator(b, false)*divexact(c, g)
   d = divexact(denominator(b, false), g)
   return parent(b)(n, d)
end

function *(a::AbstractAlgebra.FracElem{T}, b::T) where {T <: RingElem}
   g = gcd(denominator(a, false), b)
   n = numerator(a, false)*divexact(b, g)
   d = divexact(denominator(a, false), g)
   return parent(a)(n, d)
end

function *(a::T, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   g = gcd(denominator(b, false), a)
   n = numerator(b, false)*divexact(a, g)
   d = divexact(denominator(b, false), g)
   return parent(b)(n, d)
end

function +(a::AbstractAlgebra.FracElem, b::Union{Integer, Rational, AbstractFloat})
   n = numerator(a, false) + denominator(a, false)*b
   d = denominator(a, false)
   return parent(a)(n, deepcopy(d))
end

function -(a::AbstractAlgebra.FracElem, b::Union{Integer, Rational, AbstractFloat})
   n = numerator(a, false) - denominator(a, false)*b
   d = denominator(a, false)
   return parent(a)(n, deepcopy(d))
end

+(a::Union{Integer, Rational, AbstractFloat}, b::AbstractAlgebra.FracElem) = b + a

function -(a::Union{Integer, Rational, AbstractFloat}, b::AbstractAlgebra.FracElem)
   n = a*denominator(b, false) - numerator(b, false)
   d = denominator(b, false)
   return parent(b)(n, deepcopy(d))
end

function +(a::AbstractAlgebra.FracElem{T}, b::T) where {T <: RingElem}
   n = numerator(a, false) + denominator(a, false)*b
   d = denominator(a, false)
   return parent(a)(n, deepcopy(d))
end

function -(a::AbstractAlgebra.FracElem{T}, b::T) where {T <: RingElem}
   n = numerator(a, false) - denominator(a, false)*b
   d = denominator(a, false)
   return parent(a)(n, deepcopy(d))
end

+(a::T, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem} = b + a

function -(a::T, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   n = a*denominator(b, false) - numerator(b, false)
   d = denominator(b, false)
   return parent(b)(n, deepcopy(d))
end

###############################################################################
#
#   Comparisons
#
###############################################################################

@doc Markdown.doc"""
    ==(x::AbstractAlgebra.FracElem{T}, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem}

Return `true` if $x == y$ arithmetically, otherwise return `false`. Recall
that power series to different precisions may still be arithmetically
equal to the minimum of the two precisions.
"""
function ==(x::AbstractAlgebra.FracElem{T}, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   b  = check_parent(x, y, false)
   !b && return false

   return (denominator(x, false) == denominator(y, false) &&
           numerator(x, false) == numerator(y, false)) ||
          (denominator(x, true) == denominator(y, true) &&
           numerator(x, true) == numerator(y, true)) ||
          (numerator(x, false)*denominator(y, false) ==
           denominator(x, false)*numerator(y, false))
end

@doc Markdown.doc"""
    isequal(x::AbstractAlgebra.FracElem{T}, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem}

Return `true` if $x == y$ exactly, otherwise return `false`. This function is
useful in cases where the numerators and denominators of the fractions are
inexact, e.g. power series. Only if the power series are precisely the same,
to the same precision, are they declared equal by this function.
"""
function isequal(x::AbstractAlgebra.FracElem{T}, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   if parent(x) != parent(y)
      return false
   end
   return isequal(numerator(x, false)*denominator(y, false),
                  denominator(x, false)*numerator(y, false))
end

###############################################################################
#
#   Ad hoc comparisons
#
###############################################################################

@doc Markdown.doc"""
    ==(x::AbstractAlgebra.FracElem, y::Union{Integer, Rational, AbstractFloat})

Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
function ==(x::AbstractAlgebra.FracElem, y::Union{Integer, Rational, AbstractFloat})
   return (isone(denominator(x, false)) && numerator(x, false) == y) ||
          (isone(denominator(x, true)) && numerator(x, true) == y) ||
          (numerator(x, false) == denominator(x, false)*y)
end

@doc Markdown.doc"""
    ==(x::Union{Integer, Rational, AbstractFloat}, y::AbstractAlgebra.FracElem)

Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::Union{Integer, Rational, AbstractFloat}, y::AbstractAlgebra.FracElem) = y == x

@doc Markdown.doc"""
    ==(x::AbstractAlgebra.FracElem{T}, y::T) where {T <: RingElem}

Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
function ==(x::AbstractAlgebra.FracElem{T}, y::T) where {T <: RingElem}
   return (isone(denominator(x, false)) && numerator(x, false) == y) ||
          (isone(denominator(x, true)) && numerator(x, true) == y) ||
          (numerator(x, false) == denominator(x, false)*y)
end

@doc Markdown.doc"""
    ==(x::T, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem}

Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::T, y::AbstractAlgebra.FracElem{T}) where {T <: RingElem} = y == x

###############################################################################
#
#   Inversion
#
###############################################################################

@doc Markdown.doc"""
    Base.inv(a::AbstractAlgebra.FracElem)

Return the inverse of the fraction $a$.
"""
function Base.inv(a::AbstractAlgebra.FracElem)
   iszero(numerator(a, false)) && throw(DivideError())
   return parent(a)(deepcopy(denominator(a, false)),
                    deepcopy(numerator(a, false)))
end

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   check_parent(a, b)
   n1 = numerator(a, false)
   d2 = denominator(b, false)
   n2 = numerator(b, false)
   d1 = denominator(a, false)
   if d1 == n2
      n = n1*d2
      d = d1*n2
   elseif isone(d1)
      gd = gcd(n1, n2)
      if isone(gd)
         n = n1*d2
         d = deepcopy(n2)
      else
         n = divexact(n1, gd)*d2
         d = divexact(n2, gd)
      end
   elseif isone(n2)
      gd = gcd(d2, d1)
      if isone(gd)
         n = d2*n1
         d = deepcopy(d1)
      else
         n = divexact(d2, gd)*n1
         d = divexact(d1, gd)
      end
   else
      g1 = gcd(n1, n2)
      g2 = gcd(d2, d1)
      if !isone(g1)
         n1 = divexact(n1, g1)
         n2 = divexact(n2, g1)
      end
      if !isone(g2)
         d2 = divexact(d2, g2)
         d1 = divexact(d1, g2)
      end
      n = n1*d2
      d = d1*n2
   end
   return parent(a)(n, d)
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

function divexact(a::AbstractAlgebra.FracElem, b::Union{Integer, Rational, AbstractFloat})
   b == 0 && throw(DivideError())
   c = base_ring(a)(b)
   g = gcd(numerator(a, false), c)
   n = divexact(numerator(a, false), g)
   d = denominator(a, false)*divexact(c, g)
   return parent(a)(n, d)
end

function divexact(a::Union{Integer, Rational, AbstractFloat}, b::AbstractAlgebra.FracElem)
   iszero(b) && throw(DivideError())
   c = base_ring(b)(a)
   g = gcd(numerator(b, false), c)
   n = denominator(b, false)*divexact(c, g)
   d = divexact(numerator(b, false), g)
   return parent(b)(n, d)
end

function divexact(a::AbstractAlgebra.FracElem{T}, b::T) where {T <: RingElem}
   iszero(b) && throw(DivideError())
   g = gcd(numerator(a, false), b)
   n = divexact(numerator(a, false), g)
   d = denominator(a, false)*divexact(b, g)
   return parent(a)(n, d)
end

function divexact(a::T, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   iszero(b) && throw(DivideError())
   g = gcd(numerator(b, false), a)
   n = denominator(b, false)*divexact(a, g)
   d = divexact(numerator(b, false), g)
   return parent(b)(n, d)
end

function divides(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   if iszero(a)
     return true, parent(a)()
   end
   if iszero(b)
     return false, parent(a)()
   end
   return true, divexact(a, b)
end

##############################################################################
#
#  Evaluation
#
##############################################################################

function evaluate(f::FracElem{T}, V::Vector{U}) where {T <: RingElement, U <: RingElement}
    return evaluate(numerator(f), V)//evaluate(denominator(f), V)
end
  
function evaluate(f::FracElem{T}, v::U) where {T <: RingElement, U <: RingElement}
    return evaluate(numerator(f), v)//evaluate(denominator(f), v)
end

function evaluate(f::FracElem{T}, v::U) where {T <: PolyElem, U <: Integer}
    return evaluate(numerator(f), v)//evaluate(denominator(f), v)
end
 
###############################################################################
#
#   Powering
#
###############################################################################

function ^(a::AbstractAlgebra.FracElem{T}, b::Int) where {T <: RingElem}
   if b < 0
      a = inv(a)
      b = -b
   end
   return parent(a)(numerator(a)^b, denominator(a)^b)
end

##############################################################################
#
#  Derivative
#
##############################################################################

# Return the derivative with respect to `x`.
function derivative(f::Generic.Frac{T}, x::T) where {T <: MPolyElem}
    return derivative(f, var_index(x))
end
  
# Return the derivative with respect to the `i`-th variable.
function derivative(f::Generic.Frac{T}, i::Int) where {T <: MPolyElem}
    n = numerator(f)
    d = denominator(f)
    return (derivative(n, i)*d - n*derivative(d, i))//d^2
end

function derivative(f::Generic.Frac{T}) where {T <: PolyElem}
    n = numerator(f)
    d = denominator(f)
    return (derivative(n)*d - n*derivative(d))//d^2
end

###############################################################################
#
#   Square root
#
###############################################################################

@doc Markdown.doc"""
    issquare(a::AbstractAlgebra.FracElem{T}) where T <: RingElem

Return `true` if $a$ is a square.
"""
function issquare(a::AbstractAlgebra.FracElem{T}) where T <: RingElem
   return issquare(numerator(a)) && issquare(denominator(a))
end

@doc Markdown.doc"""
    Base.sqrt(a::AbstractAlgebra.FracElem{T}) where T <: RingElem

Return the square root of $a$ if it is a square, otherwise raise an
exception.
"""
function Base.sqrt(a::AbstractAlgebra.FracElem{T}) where T <: RingElem
   return parent(a)(sqrt(numerator(a)), sqrt(denominator(a)))
end

###############################################################################
#
#   GCD
#
###############################################################################

@doc Markdown.doc"""
    gcd(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}

Return a greatest common divisor of $a$ and $b$ if one exists. N.B: we define
the GCD of $a/b$ and $c/d$ to be gcd$(ad, bc)/bd$, reduced to lowest terms.
This requires the existence of a greatest common divisor function for the
base ring.
"""
function gcd(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   check_parent(a, b)
   gbd = gcd(denominator(a, false), denominator(b, false))
   n = gcd(numerator(a, false), numerator(b, false))
   d = divexact(denominator(a, false), gbd)*denominator(b, false)
   n = divexact(n, canonical_unit(n))
   d = divexact(d, canonical_unit(d))
   return parent(a)(n, d)
end

################################################################################
#
#   Remove and valuation
#
################################################################################

@doc Markdown.doc"""
    remove(z::AbstractAlgebra.FracElem{T}, p::T) where {T <: RingElem}

Return the tuple $n, x$ such that $z = p^nx$ where $x$ has valuation $0$ at
$p$.
"""
function remove(z::AbstractAlgebra.FracElem{T}, p) where {T}
   p = convert(T, p)
   iszero(z) && error("Not yet implemented")
   v, d = remove(denominator(z, false), p)
   w, n = remove(numerator(z, false), p)
   return w-v, parent(z)(deepcopy(n), deepcopy(d))
end

@doc Markdown.doc"""
    valuation(z::AbstractAlgebra.FracElem{T}, p::T) where {T <: RingElem}

Return the valuation of $z$ at $p$.
"""
function valuation(z::AbstractAlgebra.FracElem{T}, p) where {T}
   p = convert(T, p)
   v, _ = remove(z, p)
   return v
end

###############################################################################
#
#   Unsafe operators and functions
#
###############################################################################

function zero!(c::AbstractAlgebra.FracElem)
   c.num = zero!(c.num)
   if !isone(c.den)
      c.den = one(base_ring(c))
   end
   return c
end

function mul!(c::AbstractAlgebra.FracElem{T}, a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   n1 = numerator(a, false)
   d2 = denominator(b, false)
   n2 = numerator(b, false)
   d1 = denominator(a, false)
   if d1 == d2
      c.num = n1*n2
      c.den = d1*d2
   elseif isone(d1)
      gd = gcd(n1, d2)
      if isone(gd)
         c.num = n1*n2
         c.den = deepcopy(d2)
      else
         c.num = divexact(n1, gd)*n2
         c.den = divexact(d2, gd)
      end
   elseif isone(d2)
      gd = gcd(n2, d1)
      if isone(gd)
         c.num = n2*n1
         c.den = deepcopy(d1)
      else
         c.num = divexact(n2, gd)*n1
         c.den = divexact(d1, gd)
      end
   else
      g1 = gcd(n1, d2)
      g2 = gcd(n2, d1)
      if !isone(g1)
         n1 = divexact(n1, g1)
         d2 = divexact(d2, g1)
      end
      if !isone(g2)
         n2 = divexact(n2, g2)
         d1 = divexact(d1, g2)
      end
      c.num = n1*n2
      c.den = d1*d2
   end
   return c
end

function addeq!(a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   d1 = denominator(a, false)
   d2 = denominator(b, false)
   n1 = numerator(a, false)
   n2 = numerator(b, false)
   gd = gcd(d1, d2)
   if d1 == d2
      a.num = addeq!(a.num, b.num)
      if !isone(d1)
         gd = gcd(a.num, d1)
         if !isone(gd)
            a.num = divexact(a.num, gd)
            a.den = divexact(d1, gd)
         end
      end
   elseif isone(d1)
      if n1 !== n2
         a.num = mul!(a.num, a.num, d2)
         a.num = addeq!(a.num, n2)
      else
         a.num = n1*d2 + n2
      end
      a.den = deepcopy(d2)
   elseif isone(d2)
      a.num = addeq!(a.num, n2*d1)
      a.den = deepcopy(d1)
   else
      if isone(gd)
         if n1 !== n2
            a.num = mul!(a.num, a.num, d2)
            a.num = addeq!(a.num, n2*d1)
         else
            a.num = n1*d2 + n2*d1
         end
         a.den = d1*d2
      else
         q1 = divexact(d1, gd)
         q2 = divexact(d2, gd)
         a.num = q1*n2 + q2*n1
         t = gcd(a.num, gd)
         if isone(t)
            a.den = mul!(a.den, a.den, q2)
         else
            gd = divexact(d1, t)
            a.num = divexact(a.num, t)
            a.den = gd*q2
         end
      end
   end
   return a
end

function add!(c::AbstractAlgebra.FracElem{T}, a::AbstractAlgebra.FracElem{T}, b::AbstractAlgebra.FracElem{T}) where {T <: RingElem}
   d1 = denominator(a, false)
   d2 = denominator(b, false)
   n1 = numerator(a, false)
   n2 = numerator(b, false)
   gd = gcd(d1, d2)
   if d1 == d2
      c.num = n1 + n2
      if isone(d1)
         c.den = deepcopy(d1)
      else
         gd = gcd(c.num, d1)
         if isone(gd)
            c.den = deepcopy(d1)
         else
            c.num = divexact(c.num, gd)
            c.den = divexact(d1, gd)
         end
      end
   elseif isone(d1)
      c.num = n1*d2 + n2
      c.den = deepcopy(d2)
   elseif isone(d2)
      c.num = n1 + n2*d1
      c.den = deepcopy(d1)
   else
      if isone(gd)
         c.num = n1*d2 + n2*d1
         c.den = d1*d2
      else
         q1 = divexact(d1, gd)
         q2 = divexact(d2, gd)
         c.num = q1*n2 + q2*n1
         t = gcd(c.num, gd)
         if isone(t)
            c.den = q2*d1
         else
            gd = divexact(d1, t)
            c.num = divexact(c.num, t)
            c.den = gd*q2
         end
      end
   end
   return c
end

###############################################################################
#
#   Random functions
#
###############################################################################

RandomExtensions.maketype(R::AbstractAlgebra.FracField, _) = elem_type(R)

function RandomExtensions.make(S::AbstractAlgebra.FracField, vs...)
   R = base_ring(S)
   if length(vs) == 1 && elem_type(R) == Random.gentype(vs[1])
      RandomExtensions.Make(S, vs[1]) # forward to default Make constructor
   else
      make(S, make(R, vs...))
   end
end

function rand(rng::AbstractRNG,
              sp::SamplerTrivial{<:Make2{<:RingElement, <:AbstractAlgebra.FracField}})
   S, v = sp[][1:end]
   R = base_ring(S)
   n = rand(rng, v)
   d = R()
   while iszero(d)
      d = rand(rng, v)
   end
   return S(n, d)
end

rand(rng::AbstractRNG, S::AbstractAlgebra.FracField, v...) =
   rand(rng, make(S, v...))

rand(S::AbstractAlgebra.FracField, v...) = rand(GLOBAL_RNG, S, v...)

###############################################################################
#
#   Promotion rules
#
###############################################################################

promote_rule(::Type{Frac{T}}, ::Type{Frac{T}}) where T <: RingElement = Frac{T}
promote_rule(::Type{Frac{T}}, ::Type{Frac{T}}) where T <: RingElem = Frac{T}

function promote_rule(::Type{Frac{T}}, ::Type{U}) where {T <: RingElem, U <: RingElem}
   promote_rule(T, U) == T ? Frac{T} : Union{}
end

###############################################################################
#
#   Parent object call overloading
#
###############################################################################

function (a::FracField{T})(b::RingElement) where {T <: RingElement}
   return a(base_ring(a)(b))
end

function (a::FracField{T})() where {T <: RingElement}
   z = Frac{T}(zero(base_ring(a)), one(base_ring(a)))
   z.parent = a
   return z
end

function (a::FracField{T})(b::T) where {T <: RingElement}
   parent(b) != base_ring(a) && error("Could not coerce to fraction")
   z = Frac{T}(b, one(base_ring(a)))
   z.parent = a
   return z
end

function (a::FracField{T})(b::T, c::T) where {T <: RingElement}
   parent(b) != base_ring(a) && error("Could not coerce to fraction")
   parent(c) != base_ring(a) && error("Could not coerce to fraction")
   z = Frac{T}(b, c)
   z.parent = a
   return z
end

function (a::FracField{T})(b::T, c::Union{Integer, Rational, AbstractFloat}) where {T <: RingElement}
   parent(b) != base_ring(a) && error("Could not coerce to fraction")
   z = Frac{T}(b, base_ring(a)(c))
   z.parent = a
   return z
end

function (a::FracField{T})(b::Union{Integer, Rational, AbstractFloat}, c::T) where {T <: RingElement}
   parent(c) != base_ring(a) && error("Could not coerce to fraction")
   z = Frac{T}(base_ring(a)(b), c)
   z.parent = a
   return z
end

function (a::FracField{T})(b::Union{Integer, Rational, AbstractFloat}) where {T <: RingElement}
   z = Frac{T}(base_ring(a)(b), one(base_ring(a)))
   z.parent = a
   return z
end

function (a::FracField{T})(b::Integer, c::Integer) where {T <: RingElement}
   z = Frac{T}(base_ring(a)(b), base_ring(a)(c))
   z.parent = a
   return z
end

function (a::FracField{T})(b::Frac{T}) where {T <: RingElement}
   a != parent(b) && error("Could not coerce to fraction")
   return b
end

###############################################################################
#
#   FractionField constructor
#
###############################################################################

@doc Markdown.doc"""
    FractionField(R::AbstractAlgebra.Ring; cached=true)

Return the parent object of the fraction field over the given base ring $R$.
If `cached == true` (the default), the returned parent object is cached so
that it will always be returned by a call to the constructor when the same
base ring $R$ is supplied.
"""
function FractionField(R::AbstractAlgebra.Ring; cached=true)
   R2 = R
   T = elem_type(R)

   return FracField{T}(R, cached)
end
