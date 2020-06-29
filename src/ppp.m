
function [x,P]=ppp(time,obs,iobs,mode)
MAXNUM= 8;
% RTKDEMO : real-time kinematic (RTK) positioning demo.
%
% This is an implementation of demonstration for the real-time kinematic (RTK)
% positioning algorithm with GPS/GNSS. In the algorithm, parameter adjustment
% is done by the Extended Kalman-Filter using double-differenced phase
% observables. Integer ambiguity is resolved by LAMBDA/MLAMBDA method.
% Cycle-slip/outlier detection is not implemented. The reference satellite is
% fixed to the highest elevation one at the first epoch.
%
%          Copyright (C) 2006 by T.TAKASU, All rights reserved.
%
% argin  : t0    = date number by datenum.m (days)
%          time  = estimation time vector relative to day t0 0:00 (sec)
%          rref  = reference station position [x;y;z] (ecef) (m)
%          obs,iobs = observation data/index(rover:1,ref.:2) (see readrnx.m)
%          nav,inav = navigation messages/index (see readrnx.m)
%          mode  = positioning mode (0:static,1:kinematic)
%
% argout : xp    = point-pos. solution (xp(n,:)=t(n) rover pos.) (ecef) (m)
%          xs    = float solution      (xs(n,:)=t(n) rover pos.) (ecef) (m)
%          xf    = fixed solution      (xf(n,:)=t(n) rover pos.) (ecef) (m)
%
% version: $Revision: 3 $ $Date: 06/01/29 11:20 $
% history: 2006/01/26 1.1 new
C=299792458; lam=C/1.57542E9; x(1:3+MAXNUM-1,1)=nan; P=zeros(length(x));
            
for k=1:length(time)   
    if isempty(find(round(iobs(:,1))==round(time(k))))
        continue;
    end
    se_sat=1:8;
     i=find(round(iobs(:,1))==round(time(k)));     
     j = find(iobs(i,2)<=8);
    obsk=obs(j,:); iobsk=iobs(j,:);  
    % single point positioning
    % ���㶨λ�õ�����վ����rr�ͻ�׼����sat
%     [rr,t,sat,dop]=pointp(obsk,iobsk);
    rr = zeros(3,1);
    slip=zeros(MAXNUM,2);
%     if k==1, sref=sat; 
%         sats=1:31; 
%         sats(sat)=[]; 
%     end
    if k==1, sref=1; 
        sats=1:8; 
        sats(1)=[]; 
    end
%     if k>1 
%          i_pre=find(round(iobs(:,1))==round(time(k-1)));
%           j_pre = find(iobs(i_pre,2)<=8);
%         iobs_pre = iobs(j_pre,:);obs_pre=obs(j_pre,:);
%         slip = detslp_dop(obs,iobs,obs_pre,iobs_pre,1,lam);
%     end
    % temporal update of states
    % ����˫��ģ����x��Ȩ��P
    % x-[rov���ꣻL1˫��-C1/lam˫���˫��ģ����]��P-x��Ӧ��Ȩ��
    rr=[12.6777 16.059 -11.7463]';
    [x,P]=udstate(sref,sats,x,P,rr,obsk,iobsk,mode,lam,slip);    
    % observables/measurement model
%     y=lam*obs_dd(sref,sats,obsk,iobsk,1);%L1˫��
    y=lam*obs_dd(sref,sats,obsk,iobsk,2);%L1˫��
    [h,H,R]=measmodel(x(1:3),x(4:end),sref,sats,lam);    
    % measurment update of states
    [x,P]=filt(x,P,y,h,H,R);    
    % ambiguity resolution
%     xf(k,:)=fixamb(x,P)'; 
    xp(k,:)=rr(:,1)'; 
    xs(k,:)=x';
    
%     disp(sprintf('t=%5.0f: %12.3f %12.3f %12.3f : n=%d DOP=%.1f',time(k),...
%          xf(k,1:3),sum(~isnan(h)),dop));
%     end
end
    tt = 1:length(xs(:,1));
    plot(tt,xs(:,1))
    hold on
    plot(tt,xs(:,2))
    plot(tt,xs(:,3))
end   
% single point positioning -----------------------------------------------------
%���룺t0-���ڣ�obs-�۲�ֵ��iobs-�۲�ʱ�̣�nav-���ģ�inav-PRN
%�����rr-���꣨ref&rov����t-����ʱ��-���ջ��Ӳ�(ref&rov)��sat-�ο���rov��dop-DOP
function [rr,t,sat,dop]=pointp(obs,iobs)
C=299792458; f1=1.57542E9; f2=1.2276E9;
for n=1:1
    i=find(iobs(:,3)==n); tr=iobs(i(1),1); sats=iobs(i,2);
    y=obs(i,1); % ion-free pseudorange
    x=zeros(4,1); xk=ones(4,1);
    while norm(x-xk)>0.1
        [h,H,el]=prmodel(x(1:3),sats);
        i=find(~isnan(y)&~isnan(h)); H=H(i,:);
        if length(i)<4
            x(:)=nan; 
            break;
        end
        xk=x; x=x+(H'*H)\H'*(y(i)-h(i));
    end
    rr(:,n)=x(1:3); t(n)=tr-x(4)/C; % t=tr-dtr
    if n==1, [e,i]=max(el); sat=sats(i); dop=sqrt(trace(inv(H'*H))); end
end
end
% pseudorange model (ionosphere-free) ------------------------------------------
function [h,H,el]=prmodel(rr,sats)
for n=1:length(sats)
    [r,e,el(n)]=geodist(rr,sats(n));
    h(n,1)=r+2.4/sin(el(n)); H(n,:)=[e',1];%���������Ӳ�Ͷ��������
end
end
% temporal update of states ----------------------------------------------------
function [x,P]=udstate(sref,sats,x,P,rr,obs,iobs,mode,lam,~)
F=ones(length(x),1); Q=zeros(length(x),1);
if mode|isnan(x(1))
    x(1:3)=rr; 
    F(1:3)=0; 
    Q(1:3)=100; 
end
N=obs_dd(sref,sats,obs,iobs,2)-obs_dd(sref,sats,obs,iobs,1)/lam;
% i=find((isnan(x(4:end))|~isnan(slip(:,1))|~isnan(slip(:,2)))&~isnan(N)); 
i=find((isnan(x(4:end)))&~isnan(N)); x(3+i)=0; 
% x(3+i)=N(i); F(3+i)=0; Q(3+i)=10;
P=diag(F)*P*diag(F)'+diag(Q).^2;
end
% double difference of observables ---------------------------------------------
%����˫��ֵ
function y=obs_dd(sref,sats,obs,iobs,ch)
    y11=obsdat(1,sref,obs,iobs,ch);
for n=1:length(sats)
    y12=obsdat(1,sats(n),obs,iobs,ch);
    y(n,1)=y11-y12;
end
end
function y=obsdat(rcv,sat,obs,iobs,ch)
i=find(iobs(:,2)==sat&iobs(:,3)==rcv);
if ~isempty(i)
    y=obs(i(1),ch); 
else
    y=nan; 
end
end
% double difference of phase model ---------------------------------------------
% ˫��̣�h-������H-ϵ����R-
function [h,H,R]=measmodel(rr1,N,sref,sats,lam)
[r11,e11]=geodist(rr1,sref);
for n=1:length(sats)
    [r12,e12]=geodist(rr1,sats(n));
    h(n,1)=(r11-r12)+lam*N(n); 
    H(n,[1:3,3+n])=[e11'-e12',lam];
end
R=(ones(length(h))+eye(length(h)))*0.003^2;
end
% measurement update of states -------------------------------------------------
function [x,P]=filt(x,P,y,h,H,R)
i=find(~isnan(y)&~isnan(h)); H=H(i,:);
K=P*H'/(H*P*H'+R(i,i));
x=x+K*(y(i)-h(i));
P=P-K*H*P;
end
% ambiguity resolution ---------------------------------------------------------
function x=fixamb(x,P);
i=1:3; j=4:length(x); 
j=j(~isnan(x(j))&diag(P(j,j))<10^2);
[N,s]=mlambda(x(j),P(j,j),2);
if isempty(N)|s(2)/s(1)<3, x(:)=nan; 
    return, end  % ratio-test
x([i,j])=[x(i)-P(i,j)/P(j,j)*(x(j)-N(:,1));N(:,1)];
end
% geometric distance -----------------------------------------------------------
%Input: t0-date;t-epoch(obstime - recvr clkerr);rr-���ջ�����,nav
%Output:r-���ؾ�;e-�۲ⷽ��ϵ����el-���Ǹ߶Ƚǣ�dt-�����Ӳ�
function [r,e,el]=geodist(rr,sat)
% C=299792458; OMGE=7.292115167E-5;
sat_pos = [1.4118 2.8093 11.344
           1.9795 4.3758 11.3412
           1.1906 5.8387 11.3368
           -0.1482 6.2278 11.3593
           -1.4198 5.6642 11.3349
           -1.9875 4.1299 11.4931
           -1.239 2.6598 11.343
           0.1128 2.2419 11.3654];   
r=0;
% rk=1;
rs= sat_pos(sat,:);
rrs=rr-rs';
r=norm(rrs);
% while abs(r-rk)>1E-4
%     [rs,dt]=satpos(t0,t-r/C,nav);
%     rrs=rr-Rz(OMGE*r/C)*rs; rk=r; r=norm(rrs);
% end
e=rrs/r;
if norm(rr)>0
    el=-asin(rr'*e/norm(rr)); 
else
    el=pi/2; 
end
% if el*180/pi<15
%     r=nan; 
% end % elevation cutoff
end
function slip = detslp_dop(obs,iobs,obs_pre,iobs_pre,rcv,lam)
    DTTOL= 0.005; 
    MAXACC =30.0;
    i=find(iobs(:,3)==rcv); tr=iobs(i(1),1); sats=iobs(i,2);
    i_pre=find(iobs_pre(:,3)==rcv); tr_pre=iobs_pre(i_pre(1),1); sats_pre=iobs_pre(i_pre,2);
    for j = 1:length(sats)
        slip(sats(j),1) = sats(j);
        if (~find(iobs(:,2)==sats(j))||~find(iobs_pre(:,2)==sats(j)))
            continue;
       jj= find(iobs(:,2)==sats(j));   
       jj_pre= find(iobs_pre(:,2)==sats(j));
       dph=obs(jj,3)-obs_pre(jj_pre,3);
       tt=tr-tr_pre;
%  /* cycle slip threshold (cycle) */
        thres=MAXACC*tt*tt/2.0/lam+fabs(tt)*4.0;
       if abs(tt)<DTTOL
           continue;
       end
       dpt=-obs(jj,3)*tt;
        if fabs(dph-dpt)<=thres
            continue;
        else           
            slip(sats(j),2) = 1;
        end     
    end
    slip(slip(:,2)==0)=nan;
    end
end