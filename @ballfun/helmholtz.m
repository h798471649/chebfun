function u = helmholtz(f, K, BC, m, varargin)
%HELMHOLTZ   Helmholtz solver with Dirichlet or Neumann boundary conditions.
%   U = HELMHOLTZ(F, K, BC, M, N, P) is the solution to the Helmholtz
%   equation with right-hand side F, frequency K, and Dirichlet boundary
%   data U(1,lambda,theta) = @(lambda,theta) BC(lambda, theta). It uses a 
%   discretization size of M x N x P. 
%
%   U = HELMHOLTZ(F, K, BC, M) is the same as HELMHOLTZ(F, K, BC, M, M, M).
%
%   U = HELMHOLTZ(F, K, BC, M, N, P, 'neumann') is the solution to the Helmholtz
%   equation with right-hand side F, frequency K, and Dirichlet boundary
%   data U(1,lambda,theta) = @(lambda,theta) BC(lambda, theta). It uses a 
%   discretization size of M x N x P. 
%
%   U = HELMHOLTZ(F, K, BC, M, 'neumann') is the same as 
%   HELMHOLTZ(F, K, BC, M, M, M, 'neumann').
%
%   Also see POISSON.

% Parse user input
isNeumann = any(find(cellfun(@(p) strcmp(p, 'neumann'), varargin)));

if nargin > 4 && isnumeric(varargin{1})
    n = varargin{1};
else
    n = m;
end

if nargin > 5 && isnumeric(varargin{2})
    p = varargin{2};
else
    p = m;
end

if ~isNeumann
    % Use Dirichlet boundary condition
    u = helmholtz_dirichlet(f, K, BC, m, n, p);
else
    % Use Neumann boundary condition
    u = helmholtz_neumann(f, K, BC, m, n, p);
end
end

function u = helmholtz_dirichlet(f, K, BC, m, n, p)
%HELMHOLTZ   Helmholtz solver with Dirichlet boundary conditions.
%   U = HELMHOLTZ(F, K, G, m, n, p) is the solution to the Helmholtz
%   equation with right-hand side F, frequency K, and Dirichlet boundary
%   data U(1,lambda,theta) = @(lambda,theta) BC(lambda, theta). The
%   equation is discretized on a M*N*P grid in spherical coordinates.
%
% Also see POISSON, HELMHOLTZ_NEUMANN.

% Copyright 2018 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

% DEVELOPER'S NOTE: 
%
% PROBLEM: We solve:
%
%  r^2sin(th)^2u_rr + 2r(sin(th))^2u_r + (sin(th))^2u_{thth}
%  + cos(th)sin(th)u_th + u_{lamlam} + r^2sin(th)^2K^2 u = (rsin(th)).^2f(r,lam,th)
%
% on the solid sphere (r,lambda, theta) written in spherical coordinates
% with Dirichlet condition at r = 1.
%
% METHOD: Spectral method (in coeff space) and Double Fourier sphere method.
% We use the Fourier basis in the theta- and lambda-direction and
% ultraspherical in r.
%
% LINEAR ALGEBRA: Matrix equation solver in (r,theta), using Bartels--Stewart
% algorithm and QZ. The matrix decouples in lambda.
%
% SOLVE COMPLEXITY:    O( n^4 )  N = n^3 = total degrees of freedom

% Adjust the size
F = coeffs3(f,m,n,p);

% The code was written with variables in the order theta, r, lambda
ord = [3 1 2];
F = permute(F, ord);

% Construct useful spectral matrices (see list above) in r and theta:
DC2 = ultraS.diffmat(m, 2);
S12 = ultraS.convertmat(m, 1, 1);
Mr = ultraS.multmat( m, [0;1], 1);
Mr2 = ultraS.multmat(m, [0.5;0;0.5], 2 );
DC1 = ultraS.diffmat( m, 1);
Msin2 = trigspec.multmat(p, [-.25;0;0.5;0;-0.25] );
I = speye(p);
S02 = ultraS.convertmat(m, 0, 1);
DF2 = trigspec.diffmat(p, 2);
Mcossin = trigspec.multmat(p, [0.25i;0;0;0;-0.25i] );
DF1 = trigspec.diffmat(p, 1);
% 2nd Fourier diffmat in lam
DF2lam = trigspec.diffmat(n, 2);

% Boundary conditions:
%
% We know that
%
% v(\pm1,lam,th) = sum_{ijk} c_{ijk} exp(1i*i*lam*pi)*T_j(\pm1)*exp(1i*k*th*pi)
%
%  and
%
% g(lam,th) = sum_{ik} g_{ik} exp(1i*i*lam*pi)*exp(1i*k*th*pi).
%
% Thus, for a fix i and k, we have
%
%         sum_{j} c_{ijk}T_j(1)   =    g_{ik}.

%% Remove this in Julia
% if g = function_handle of lambda, th
if isa(BC, 'function_handle')
    % Grid
    th = pi*trigpts(p);
    lam = pi*trigpts(n);
    % Evaluate function handle at tensor grid:
    [ll, tt] = ndgrid(lam, th);
    BC1 = feval(BC, ll, tt).';
    % Test if the function is constant
    if size(BC1) == 1
        BC1 = ones(p,n)*BC1(1);
    end
    % Convert boundary conditions to coeffs:
    BC1 = trigtech.vals2coeffs( trigtech.vals2coeffs( BC1 ).' ).';
    
%% if g is an array of fourier coefficients lambda x theta
else
    % BC1 is an array of coefficients theta x lambda of size [m,n,p]
    BC = trigtech.alias(trigtech.alias(BC.',p).',n);
    BC1 = BC.';
end

% Use the symmetries to find BC2
BC2 = (-1).^((1:p)-floor(p/2)-1).'.*BC1;

% Fortunately, the PDE decouples in the lambda variable.
CFS = zeros(p, m, n);

% Solve the Helmholtz equation
if abs(K)>1
    % Divide by K^2
    Lr = Mr2*DC2/K^2 + 2*S12*Mr*DC1/K^2 + Mr2*S02;
else
    Lr = Mr2*DC2 + 2*S12*Mr*DC1 + K^2*Mr2*S02;
end

Lth = Msin2*DF2+Mcossin*DF1;
bc1 = (ones(1,m) + (-1).^(0:m-1))/2;
bc2 = (ones(1,m) - (-1).^(0:m-1))/2;
myS02 = S02; 
myLr = Lr; 
c1 = myS02(:,1);
myS02 = myS02 - myS02(:,1)*bc1;
c2 = myS02(:,2);
myS02 = myS02 - myS02(:,2)*bc2;
c3 = myLr(:,1);
myLr = myLr - myLr(:,1)*bc1;
c4 = myLr(:,2);
myLr = myLr - myLr(:,2)*bc2;

%% Solve the linear system only if f(:,:,k) ~= 0 or BC1(:,k) ~= 0 or 
% BC2(:,k) ~= 0
ListFourierMode = [];
for k = 1:n
    if norm(F(:,:,k),inf) > 1e-16 || norm(BC1(:,k),inf) > 1e-16 || norm(BC2(:,k),inf) > 1e-16
        ListFourierMode = [ListFourierMode k];
    end
end

for k = ListFourierMode
    % X(:,:,k) is the solution to 2D PDE:
    %
    %  kron(M_{r^2}D_2^C + 2S_{12}M_rD_1^C, M_{sin(th)^2} ) + ...
    %             kron(S_{02}, M_{sin(th)^2}D_2^F + M_{cos(th)sin(th)}D_1^F + D_2^Flam(k,k)*I )
    
    A = Lth + DF2lam(k,k)*I;
    
    % Multiply F by r^2*sin(th)^2
    ff = Msin2*F(:,:,k)*S02.'*Mr2.';

    if abs(K)>1
        % Divide Lth and f by K^2
        A = A/K^2;
        ff = ff/K^2;
    end
    
    % Eliminating boundary conditions, changes rhs:
    ff = ff - (A*(BC1(:,k)+BC2(:,k))/2)*c1';
    ff = ff - (A*(BC1(:,k)-BC2(:,k))/2)*c2';
    ff = ff - (Msin2*(BC1(:,k)+BC2(:,k))/2)*c3';
    ff = ff - (Msin2*(BC1(:,k)-BC2(:,k))/2)*c4';
    
    % Solve resulting Sylvester matrix equation: 
    X = chebop2.bartelsStewart(Msin2,myLr(1:end-2,3:end),A,...
        myS02(1:end-2,3:end),ff(:,1:end-2),0,0);
    
    % Put the bcs back in:
    col1 =  (BC1(:,k)+BC2(:,k))/2 - X * bc1(3:end).';
    col2 =  (BC1(:,k)-BC2(:,k))/2 - X * bc2(3:end).';
    
    CFS(:, :, k) = [col1 col2 X];
end

% Permute back: 
ord = [2 3 1];
CFS = permute( CFS, ord);

% Create ballfun object: 
u = ballfun( CFS, 'coeffs');
end

function u = helmholtz_neumann(f, K, BC, m, n, p)
%HELMHOLTZ_NEUMANN   Helmholtz solver with Dirichlet boundary conditions.
%   U = HELMHOLTZ_NEUMANN(F, K, BC, m, n, p) is the solution to the Helmholtz
%   equation with right-hand side F, frequency K, and Neumann boundary
%   data U(1,lambda,theta) = @(lambda,theta) BC(lambda, theta). The
%   equation is discretized on a M*N*P grid in spherical coordinates.
%
% Also see POISSON, HELMHOLTZ.

% Copyright 2018 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

% DEVELOPER'S NOTE: 
%
% PROBLEM: We solve:
%
%  r^2sin(th)^2u_rr + 2r(sin(th))^2u_r + (sin(th))^2u_{thth}
%  + cos(th)sin(th)u_th + u_{lamlam} + r^2sin(th)^2K^2 u = (rsin(th)).^2f(r,lam,th)
%
% on the solid sphere (r,lambda, theta) written in spherical coordinates
% with Dirichlet condition at r = 1.
%
% METHOD: Spectral method (in coeff space) and Double Fourier sphere method.
% We use the Fourier basis in the theta- and lambda-direction and
% ultraspherical in r.
%
% LINEAR ALGEBRA: Matrix equation solver in (r,theta), using Bartels--Stewart
% algorithm and QZ. The matrix decouples in lambda.
%
% SOLVE COMPLEXITY:    O( n^4 )  N = n^3 = total degrees of freedom

% Adjust the size
F = coeffs3(f,m,n,p);

% The code was written with variables in the order theta, r, lambda
ord = [3 1 2];
F = permute(F, ord);

% Construct useful spectral matrices (see list above) in r and theta:
DC2 = ultraS.diffmat(m, 2);
S01 = ultraS.convertmat(m, 0, 0);
S02 = ultraS.convertmat(m, 0, 1);
S12 = ultraS.convertmat(m, 1, 1);
Mr = ultraS.multmat( m, [0;1], 1);
Mr2 = ultraS.multmat(m, [0.5;0;0.5], 2 );
DC1 = ultraS.diffmat( m, 1);
Msin2 = trigspec.multmat(p, [-.25;0;0.5;0;-0.25] );
I = speye(p);
DF2 = trigspec.diffmat(p, 2);
Mcossin = trigspec.multmat(p, [0.25i;0;0;0;-0.25i] );
DF1 = 1i*spdiags((-floor(p/2):floor(p/2))', 0, p, p);
% 2nd Fourier diffmat in lam
DF2lam = trigspec.diffmat(n, 2);

% Boundary conditions:
%
% We know that
%
% v(\pm1,lam,th) = sum_{ijk} c_{ijk} exp(1i*i*lam*pi)*T_j(\pm1)*exp(1i*k*th*pi)
%
%  and
%
% g(lam,th) = sum_{ik} g_{ik} exp(1i*i*lam*pi)*exp(1i*k*th*pi).
%
% Thus, for a fix i and k, we have
%
%         sum_{j} c_{ijk}T_j(1)   =    g_{ik}.

% if g = function_handle of lambda, th
if isa(BC, 'function_handle')
    % Grid
    th = pi*trigpts(p);
    lam = pi*trigpts(n);
    % Evaluate function handle at tensor grid:
    [ll, tt] = ndgrid(lam, th);
    BC1 = feval(BC, ll, tt).';
    % Test if the function is constant
    if size(BC1) == 1
        BC1 = ones(p,n)*BC1(1);
    end
    % Convert boundary conditions to coeffs:
    BC1 = trigtech.vals2coeffs( trigtech.vals2coeffs( BC1 ).' ).';
    % if g is an array of fourier coefficients lambda x theta   
else
    % BC1 in an array of coefficients theta x lambda of size [m,n,p]
    BC = trigtech.alias(trigtech.alias(BC.',p).',n);
    BC1 = BC.';
end

% BC1 is the derivative of a smooth function on the ball, which contains
% element of the form r^k exp(i*n*theta) where mod(k,2) = mod(n,2)
BC2 = (-1).^((1:p)-floor(p/2)).'.*BC1;

% Fortunately, the PDE decouples in the lambda variable.
CFS = zeros(p, m, n);

% Solve the Helmholtz equation
if abs(K)>1
    % Divide by K^2
    Lr = Mr2*DC2/K^2 + 2*S12*Mr*DC1/K^2 + Mr2*S02;
else
    Lr = Mr2*DC2 + 2*S12*Mr*DC1 + K^2*Mr2*S02;
end

Lth = Msin2*DF2+Mcossin*DF1;
bc1 = (ones(1,m) + (-1).^(0:m-1))/2;
bc2 = (ones(1,m) - (-1).^(0:m-1))/2;
bc1 = bc1*(S01\DC1);
bc2 = bc2*(S01\DC1);

% Divide bc2 by 4 so that the (2:3,2:3) entries of [bc1 ; bc2] are the
% 2x2 identity matrix.
bc2 = bc2/4;

% Use boundary rows to extract degrees of freedom from X(:,:,k):
myS02 = S02;
myLr = Lr;
c1 = myS02(:,2);
myS02 = myS02 - myS02(:,2)*bc1;
c2 = myS02(:,3);
myS02 = myS02 - myS02(:,3)*bc2;
c3 = myLr(:,2);
myLr = myLr - myLr(:,2)*bc1;
c4 = myLr(:,3);
myLr = myLr - myLr(:,3)*bc2;

% Solve the linear system only if f(:,:,k) ~= 0 or BC1(:,k) ~= 0 or
% BC2(:,k) ~= 0
ListFourierMode = [];
for k = 1:n
    if (max(max(abs(F(:,:,k)))) > 1e-16) || (max(abs(BC1(:,k))) > 1e-16) || (max(abs(BC2(:,k))) > 1e-16)
        ListFourierMode = [ListFourierMode k];
    end
end

for k = ListFourierMode
    
    % X(:,:,k) is the solution to 2D PDE:
    %
    %  kron(M_{r^2}D_2^C + 2S_{12}M_rD_1^C, M_{sin(lam)^2} ) + ...
    %             kron(S_{02}, M_{sin(lam)^2}D_2^F + M_{cos(th)sin(th)}D_1^F + D_2^Flam(k,k)*I )
    
    A = Lth + DF2lam(k,k)*I;
    
    % Multiply F by r^2sin(th)^2
    ff = Msin2*F(:,:,k)*S02.'*Mr2.';
    
    if abs(K)>1
        % Divide Lth and f by K^2
        A = A/K^2;
        ff = ff/K^2;
    end
    
    % Add one condition for the 0th Fourier mode if K = 0:
    % the 0th Fourier mode in lambda and theta is 0
    if k == floor(n/2)+1 && K == 0
                
        % Increase m if it isn't equal to 3 mod 4
        if mod(m,4) ~= 3
            mexp = m + mod(3-mod(m,4),4);
            DC2Exp = ultraS.diffmat(mexp, 2);
            S01Exp = ultraS.convertmat(mexp, 0, 0);
            S12Exp = ultraS.convertmat(mexp, 1, 1);
            MrExp = ultraS.multmat(mexp, [0;1], 1);
            Mr2Exp = ultraS.multmat(mexp, [0.5;0;0.5], 2 );
            DC1Exp = ultraS.diffmat(mexp, 1);
            S02Exp = ultraS.convertmat(mexp, 0, 1);
            LrExp = Mr2Exp*DC2Exp + 2*S12Exp*MrExp*DC1Exp;
            bc1Exp = (ones(1,mexp) + (-1).^(0:mexp-1))/2;
            bc2Exp = (ones(1,mexp) - (-1).^(0:mexp-1))/2;
            bc1Exp = bc1Exp*(S01Exp\DC1Exp);
            bc2Exp = bc2Exp*(S01Exp\DC1Exp)/4;
        else
            mexp = m;
            LrExp = Lr;
            S02Exp = S02;
            bc1Exp = bc1;
            bc2Exp = bc2;
        end
        
        % Increase p if it isn't equal to 1 mod 4
        if mod(p,4) ~= 1
            pexp = p + mod(1-mod(p,4),4);
            Msin2Exp = trigspec.multmat(pexp, [-.25;0;0.5;0;-0.25] );
            DF2Exp = trigspec.diffmat(pexp, 2);
            McossinExp = trigspec.multmat(pexp, [0.25i;0;0;0;-0.25i] );
            DF1Exp = 1i*spdiags((-floor(pexp/2):floor(pexp/2))', 0, pexp, pexp);
            LthExp = Msin2Exp*DF2Exp+McossinExp*DF1Exp;
        else
            pexp = p;
            Msin2Exp = Msin2;
            LthExp = Lth;
        end
        
        % Expand ff
        ffExp = zeros(pexp,mexp);
        ffExp(floor(pexp/2)+1-floor(p/2):floor(pexp/2)+p-floor(p/2),1:m) = ff;
        
        BC1Exp = zeros(pexp,1);
        BC2Exp = zeros(pexp,1);
        BC1Exp(floor(pexp/2)+1-floor(p/2):floor(pexp/2)+p-floor(p/2)) = BC1(:,k);
        BC2Exp(floor(pexp/2)+1-floor(p/2):floor(pexp/2)+p-floor(p/2)) = BC2(:,k);
        
        % Select m-2 rows to add the Neumann BC
        ii = 1:mexp-2;
        
        B = kron( LrExp(ii,:),Msin2Exp ) + kron( S02Exp(ii,:), LthExp );

        b1 = kron(bc1Exp,speye(pexp));
        b2 = kron(bc2Exp,speye(pexp));
        
        B = [ b1 ; b2 ; B ];
        % Remove the 0-th row
        B = [B(:,1:floor(pexp/2)),B(:,floor(pexp/2)+2:end)];
        B(end,:) = []; 
        
        ffExp = ffExp(:,ii);
        ffExp = ffExp(:);
        ffExp(end) = [];
        
        % Solve the linear system
        xk = B \ [ (BC1Exp+BC2Exp)/2; (BC1Exp-BC2Exp)/8 ; ffExp ];
        xk = [xk(1:floor(pexp/2)) ; 0 ; xk(floor(pexp/2)+1:end)];
        xk = reshape(xk,pexp,mexp);
        
        % Truncate
        if mexp ~= m
            xk = chebtech2.alias(xk.', m).';
        end
        if pexp ~= p
            xk = trigtech.alias(xk, p);
        end
        
        % Fill in the tensor of coeffs
        CFS(:, :, k) = xk;
        
    else
        % Solve resulting Sylvester matrix equation:
            % Eliminating boundary conditions, changes rhs:
        ff = ff - (A*(BC1(:,k)+BC2(:,k))/2)*c1';
        ff = ff - (A*(BC1(:,k)-BC2(:,k))/8)*c2';
        ff = ff - (Msin2*(BC1(:,k)+BC2(:,k))/2)*c3';
        ff = ff - (Msin2*(BC1(:,k)-BC2(:,k))/8)*c4';
    
        X = chebop2.bartelsStewart(Msin2,myLr(1:end-2,[1 4:end]),A,...
            myS02(1:end-2,[1 4:end]),ff(:,1:end-2),0,0);
        %     warning('on',id)

        % Put the bcs back in:
        col2 = (BC1(:,k)+BC2(:,k))/2 - X * bc1([1 4:end]).';
        col3 = (BC1(:,k)-BC2(:,k))/8 - X * bc2([1 4:end]).';
        
        CFS(:, :, k) = [X(:,1) col2 col3 X(:,2:end)];
    end
end


% Permute back:
ord = [2 3 1];
CFS = permute( CFS, ord);

% Create ballfun object:
u = ballfun( CFS, 'coeffs' );
end