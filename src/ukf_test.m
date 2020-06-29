function [Xa,Pa] = ukf_test(X,P,rr,sref,sats,obsk,iobsk,mode)
[X,P]=ukf_state_update(sats,X,P,rr,obsk,iobsk,mode);
i = find(~isnan(X));
Xa = X;
Pa = P;
beta=2;
elfa=0.001;
nx=size(X,1);
kappa=3-nx;
% kappa=0;
%lambda=((elfa^2)*(nx+kappa)-nx);%��ut_weights��߼���   
[wm,wc,c]=ut_weights(nx,elfa,beta,kappa);%����Ȩ��
XX=ut_sigmas(Xa,Pa,c);%����sigma�㣬XX��sigma�㣬X״̬������P�Ƿ���   
z = zeros(8,1);
z=obs_dds(sref,sats,obsk,iobsk,2);%L1  
z(find(z == 0)) = nan;
ii = find(~isnan(z));
[Xa,Pa,zz,Pzz,Pxz]=ukf_predict(XX,wm,wc,nx,sref,iobsk,mode);
[Xa,Pa]=ukf_update(Pxz,Pzz,Pa,z(ii),zz,Xa);
X(i)=Xa;
P(i,i)=Pa;
end

