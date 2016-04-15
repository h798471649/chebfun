function H = cross( F, G )
%CROSS   Vector cross product.
%   CROSS(F, G) returns the CHEBFUN3V representing the 3D cross 
%   product of the CHEBFUN3V objects F and G. 

% Empty check: 
if ( isempty( F ) || isempty( G ) )
    H = chebfun3v;
    return
end

% Get number of components: 
Fc = F.components; 
Gc = G.components; 

if ( F.nComponents == 3 && G.nComponents == 3 )
    H = [ Fc{2} .* Gc{3} - Fc{3} .* Gc{2};
          Fc{3} .* Gc{1} - Fc{1} .* Gc{3};
          Fc{1} .* Gc{2} - Fc{2} .* Gc{1}];
else
    error('CHEBFUN:CHEBFUN3V:cross:components', ...
        'CHEBFUN3V objects must be both 3-vectors.');
end

end