
for f in (:getindex, :view, :dotview)
    @eval begin
        # Regular span needs its span size updated
        @propagate_inbounds Base.$f(l::AbstractSampled, i::AbstractRange) = 
            rebuild(l; data=Base.$f(parent(l), i), span=slicespan(l, i))
        # Int and CartesianIndex forward to the parent
        @propagate_inbounds Base.$f(l::LookupArray, i::Union{Int,CartesianIndex}) =
            Base.$f(parent(l), i)
        # AbstractArray and Colon the lookup is rebuilt around a new parent
        @propagate_inbounds Base.$f(l::LookupArray, i::Union{AbstractArray,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        # Selector gets processed with `selectindices`
        @propagate_inbounds Base.$f(l::LookupArray, i::SelectorOrInterval) = Base.$f(l, selectindices(l, i))
        # Everything else (like custom indexing from other packages) passes through to the parent
        @propagate_inbounds Base.$f(l::LookupArray, i) = Base.$f(parent(l), i)
        @propagate_inbounds Base.$f(l::NoLookup, i::Int) = i

        # We need to change the direction when we index with a reversed OrdinalRange
        # but unfortunately this makes regular indexing with OrdinalRange type unstable,
        # adding ~200ns to `view`
        # @propagate_inbounds Base.$f(l::AbstractSampled, i::OrdinalRange) = 
            # rebuild(l; data=Base.$f(parent(l), i), span=slicespan(l, i), order=_maybe_reverse(order(l), i))
    end
end
