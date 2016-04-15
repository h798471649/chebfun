function G = divgrad(F)
%DIVGRAD   Laplacian of a CHEBFUN3V.
%   F = DIVGRAD(F) returns the Laplacian of a CHEBFUN3V i.e.,
%       divgrad(F) = F(1)_xx + F(2)_yy + F(3)_zz
%
% This command is defined only for a chebfun3v with 3 components. 
%
% Also see CHEBFUN3V/LAP.

nComponents = F.nComponents; 
if ( (nComponents < 3) || (nComponents > 3) ) 
    error('CHEBFUN:CHEBFUN3V:divgrad:components',...
        'Command is defined only for CHEBFUN3V objects with 3 components.')
end
     
Fc = F.components; 
G = diff(Fc{1}, 2, 1) + diff(Fc{2}, 2, 2) + diff(Fc{3}, 2,3); 
 
end