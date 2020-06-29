function [xs,xres] =ppp_SD(time,obs,iobs,mode,type)
% fid=fopen('output_debug.txt', 'wt');;
MAXNUM= 8;
Window_size = 1;
track = zeros(8,1);
count=1;
% argin  : time  = estimation time vector relative to day t0 0:00 (sec)
%          obs,iobs = observation data/index(rover:1,ref.:2) (see readrnx.m)
%          mode  = positioning mode (0:static,1:kinematic)
% argout : x,p    = point-pos. solution (x,p(n,:)=t(n) rover pos.) (ecef) (m)
C=299792458; 
lam=C/1.57542E9; 
N_res = [];
if type == 1
    numSamples=100;
    for i= 1:numSamples
        x(1:3+MAXNUM,i)=nan; 
    end   
else
    x(1:3+MAXNUM,1)=nan; 
    P=zeros(length(x),length(x));  
end     
for k=1:length(time)
    if k>6000
        break;
    end
    if isempty(find(round(1000*iobs(:,1))==round(1000*time(k))))
        continue;
    end
     sref=1; sats=1:8; 
     i=find(round(1000*iobs(:,1))==round(1000*time(k)));     
     j = find(iobs(i,2)<=8&iobs(i,2)>0);
     iobskk=iobs(i,:);obskk=obs(i,:);
     obsk=obskk(j,:); iobsk=iobskk(j,:);  
     % single point positioning
     rr = zeros(3,1);
    if length(j)<4
        continue;
    end
     slip=zeros(MAXNUM,2);
    if k>1 
        i_pre=find(round(1000*iobs(:,1))==round(1000*time(k-1)));
       if ~isempty(i_pre)
         j_pre = find(iobs(i_pre,2)<=8);
         iobs_pre = iobs(i_pre,:);obs_pre=obs(i_pre,:);
%          [slip,track] = detslp_dop(obsk,iobsk,obs_pre(j_pre,:),iobs_pre(j_pre,:),lam,track);
        end         
    end
    sref = getrefsat(sats,iobsk,slip);
    if isempty(sref)
        continue;
    end
%     rr=[2.6777 6.059 -1.7463]';true value
   if k<150
      mode = 0;
   else
      mode = 1;
   end
       x_mul = multipath(obsk,iobsk,sats);
       x_multapath(k,:)=x_mul;
       
%       if k < 10            
%           x_multapath(k,:)= mean(x_multapath(:,:),1);
%       else
%           x_multapath(k,:)= mean(x_multapath((k-10+1):end,:),1);        
%        end

       y=obs_dds(sref,sats,obsk,iobsk,2);%L1
       y_code=obs_dds(sref,sats,obsk,iobsk,1);%L1
%        rr=[0.025 3.317 -0.530]';
%        rr=[-2.9701 5.7737 -0.3562]';%GPS-2 123
%           rr=[-2.7025 0.3928 -0.3819]';%GPS-3
%          rr=[-2.7025 0.3928 -0.3819]';%GPS-3
%         rr=[2.6777 	6.0590 -0.3879]';%GPS-7
%          rr=[3.0223 	0.7152 -0.3879]';%121   
%        rr=[2.681 0.662 -0.430]';
      rr=[-2.917 5.724 -0.441]';
      if type == 0
          [x,P] = ukf_test(x,P,rr,sref,sats,obsk,iobsk,mode);   
      elseif type == 1
          [x,pfx] = pf_test(x,rr,sref,sats,obsk,iobsk,mode);
      else
%            if ~mode
%           m = size(N_res,1);
%             if m>10
%             for ss = 1:8               
%                 if std(N_res(:,ss))<0.001                    
%                     mode = 1;
%                 else
%                     mode = 0;
%                     break;
%                 end
%             end   
%             end 
%            [x,P]=udstate(sats,x,P,rr,obsk,iobsk,mode,lam);
%           [h,H,R]=measmodel(x(1:3),x(4:end),sref,sats,lam,mode); 
%            x(3) = rr(3);      
%           [x,P]=filt(x,P,y,h,H,R); 
%            else
%            end

%           [x,P]=udstate(sats,x,P,rr,obsk,iobsk,mode,lam);
%           [h,H,R]=measmodel(x(1:3),x(4:end),sref,sats,lam,mode); 
%            x(3) = rr(3);      
%           [x,P]=filt(x,P,y,h,H,R); 
%            [m,n] = size(N_res);
%           if m>10
%              for ss = 1:n               
%                 if std(N_res(:,ss))<0.001                    
%                     mode = 1;
%                 else
%                     mode = 0;
%                     break;
%                 end
%              end   
%           end 
          [x,P]=udstate(sats,x,P,rr,obsk,iobsk,mode,lam,slip);
          [h,H,R,track]=measmodel(x(1:3),x(4:end),sref,sats,lam,mode,slip,track); 
          x(3) = rr(3);      
          [x,P]=filt(x,P,y,h,H,R,slip,mode);
%           xv = resdop(x(1:3),sats,sref,obsk(:,3),iobsk(:,2));
          if mode
            [x,P] = restoreAmb(x,P,obsk,iobsk,sats,sref,slip,y);
          end
            [m,n] = size(N_res);
            if m>30
              for ss = 1:n               
                if std(N_res(:,ss))<0.001                    
                    mode = 1;
                else
                    mode = 0;
                    break;
                end
              end   
            end  
%           if ~mode    
% %           [x,P]=udstate(sats,x,P,rr,obsk,iobsk,mode,lam);
% %           [h,H,R]=measmodel(x(1:3),x(4:end),sref,sats,lam,mode); 
% %            x(3) = rr(3);      
% %           [x,P]=filt(x,P,y,h,H,R); 
%           [h,H,R]=measmodel(x(1:3),x(4:end),sref,sats,lam,mode); 
%            x(3) = rr(3);      
%           [x,P]=filt(x,P,y,h,H,R); 
%             [m,n] = size(N_res);
%             if m>30
%               for ss = 1:n               
%                 if std(N_res(:,ss))<0.001                    
%                     mode = 1;
%                 else
%                     mode = 0;
%                     break;
%                 end
%               end   
%             end           
%           else
%               [xa,cycle]=mulNewtonSOR(x(1:3)',x(4:end),sref,sats,lam,y,mode);
% %               [xa,cycle]=LM(F(i),xsys,x(1:2)');
%               x(1:3) = xa;
% %              r_res = Optimalsearch(x,sref,sats,lam,y);
% %              x(1:2) = r_res(1,1:2);
%           end
      end      
    % [xa,Pa]=ddmat(x,P);
    % ambiguity resolution
    % xf(k,:)=fixamb(xa,Pa)';     
    if(type == 1)
       res = measmodel_res(pfx(1:3),pfx(4:end),sref,iobsk,lam,y);
       xs(k,:)=pfx(1:3)';   
       xres(k,:)=res;
    else
       res = measmodel_res(x(1:3),x(4:end),sref,sats,lam,y);
       isused = zeros(8,1);
       isused = Validitytest(isused,res);
       xs(k,:)=x(1:3)';   
       xres(k,:)=res;
    end
       Na = Na_dds(sref,sats,x);%L1
       phase_res(k,:)=y';
       code_res(k,:)=y_code';
       N_res(k,:) = Na';     
%        V_res(k,:) = xv';
       count=count+1;
       Window_size = Window_size+1;
       slip_res(k,:) = slip(:,2);      
end
%     figure(11);
     tt = 1:length(xs(:,1));
%     subplot(3,1,1)    
%     plot(tt,V_res(:,1),'LineWidth',3)
%     title('xs');
%     subplot(3,1,2)
%     plot(tt,V_res(:,2),'LineWidth',3)
%     subplot(3,1,3)
%     plot(tt,V_res(:,3),'LineWidth',3)
%     tt = 1:length(xs(:,1));
    figure(1);
    subplot(4,1,1)    
    plot(tt,xs(:,1),'LineWidth',3)
    title('xs');
    subplot(4,1,2)
    plot(tt,xs(:,2),'LineWidth',3)
    subplot(4,1,3)
    plot(tt,xs(:,3),'LineWidth',3)
    subplot(4,1,4)
    plot(xs(:,1),xs(:,2),'LineWidth',3)
    ylabel('PlaneTrack(m)','fontsize',10);
    
    figure(2)
    subplot(2,1,1) 
    [m,n]=size(phase_res);
     plot(1:m,phase_res(:,1),'LineWidth',3);
     hold on;
    for i = 2:n
        plot(1:m,phase_res(:,i),'LineWidth',3);
    end
    title('phase_res');
    ylabel('phase-res (m)','fontsize',20);
     subplot(2,1,2)
     [m,n]=size(code_res);
     plot(1:m,code_res(:,1),'LineWidth',3);
     hold on;
     for i = 2:n
        plot(1:m,code_res(:,i),'LineWidth',3);
     end
     ylabel('code-res (m)','fontsize',20);
     
%      carrier = phase_res(1001:2000,:);
%      save carrier9.mat carrier;
%      code = code_res(1001:2000,:);
%      save code9.mat code;
     
     
%      figure(3);
%      [m,n]=size(N_res);
%       plot(1:m, N_res,'LineWidth',3);
%       ylabel('amb-res (m)','fontsize',20);
      
     figure(5);
     [m,n]=size(x_multapath);
     plot(1:m,x_multapath(:,1),'LineWidth',3);
     hold on;
     for i = 2:n
        plot(1:m,x_multapath(:,i),'LineWidth',3);
     end
     title('multipath');
     ylabel('multipath (m)','fontsize',20);
     
%      figure(10);
%      [m,n]=size(slip_res);
%      plot(1:m,slip_res(:,1),'LineWidth',3);
%      hold on;
%      for i = 2:n
%         plot(1:m,slip_res(:,i),'LineWidth',3);
%      end
%      title('slip_res');
%      ylabel('slip_res (m)','fontsize',20);
end
function Na = Na_dds(sref,sats,x)
i = find(sats==sref);k = 1;
for j = 1:length(sats)
    if i == j
        continue;
    end
    Na(k)=x(3+i)-x(3+j);
    k=k+1;
end
end
% single point positioning -----------------------------------------------------
%���룺t0-���ڣ�obs-�۲�ֵ��iobs-�۲�ʱ�̣�nav-���ģ�inav-PRN
%�����rr-���꣨ref&rov����t-����ʱ��-���ջ��Ӳ�(ref&rov)��sat-�ο���rov��dop-DOP
function [rr,sat,dop]=pointp_SD(obs,iobs)
C=299792458; f1=1.57542E9; f2=1.2276E9;
    i=find(iobs(:,3)==1); 
    sats=iobs(i,2);
    y=obs(i,1); % ion-free pseudorange
    x=zeros(3,1); xk=ones(3,1);
    while norm(x-xk)>0.1
        HH = [];H=[];h=[];yy=[];
        [h,H,el]=prmodel_SD(x(1:3),sats);
        i=find(~isnan(y)&~isnan(h)); 
        if length(i)<4
            x(:)=nan; 
            break;
        end
        HH=H(2:end,:)-H(1,:);
        hh = h(2:end,:)-h(1,:);
        yy = y(2:end,:)-y(1,:);    
        xk = x;
        x=x+(HH'*HH)\HH'*(yy-hh);
    end
    rr=x;
    [e,i]=max(el); sat=sats(i); 
    dop=sqrt(trace(inv(H'*H))); 
end
function [rr,sat,dop]=pointp_SD_cp(obs,iobs)
C=299792458; f1=1.57542E9;
lam = C/f1;
    i=find(iobs(:,3)==1);sats=iobs(i,2);
    yc=obs(i,1); % ion-free pseudorange
    yp=obs(i,2); 
    n = length(yp);
    x=zeros(3+n,1); xk=ones(3+n,1);
    while norm(x-xk)>0.1
        [h,H,el]=prmodel_SD(x(1:3),sats);
        i=find(~isnan(yc)&~isnan(h)&~isnan(yp)); 
         if length(i)<4
            x(:)=nan; 
            break;
         end
         HH=[];
        for j=2:n
            a = H(1,:)'-H(j,:)';
            b = [sats(1)+3 sats(j)+3];
            HH(j-1,[1:3,b])=[a',[lam,-lam]];
        end
        Hc = zeros(n-1,3+n);
        Hc(:,1:3)=H(2:end,:)-H(1,:);
        HH = [HH;Hc];
        yy1 = lam*yp(1)-lam*yp(2:end);
        yy2 = yc(1)-yc(2:end);
        hh = h(1)-h(2:end);
        hh = [hh;hh];
        yy = [yy1;yy2];
        x=x+(HH'*HH)\HH'*(yy-hh);
    end
    rr=x(1:3);
    [e,i]=max(el); sat=sats(i); 
    dop=sqrt(trace(inv(H'*H))); 
end
function [rr,t,sat,dop]=pointp(obs,iobs)
C=299792458; f1=1.57542E9; f2=1.2276E9;
    i=find(iobs(:,3)==1); 
    tr=iobs(i(1),1); 
    sats=iobs(i,2);
    y=obs(i,1); % ion-free pseudorange
    x=zeros(4,1); 
    xk=ones(4,1);
    while norm(x-xk)>0.1
        [h,H,el]=prmodel(x(1:3),sats);
        i=find(~isnan(y)&~isnan(h)); 
        H=H(i,:);
        if length(i)<4
            x(:)=nan; 
            break;
        end
        xk=x; x=x+(H'*H)\H'*(y(i)-h(i));
    end
    rr=x(1:3); 
    t=tr-x(4)/C; % t=tr-dtr
    [e,i]=max(el);
    sat=sats(i); 
    dop=sqrt(trace(inv(H'*H)));
end
% pseudorange model (ionosphere-free) ------------------------------------------
function [h,H,el]=prmodel_SD(rr,sats)
for n=1:length(sats)
    [r,e,el(n)]=geodist(rr,sats(n));
    h(n,1)=r; 
    H(n,:)=e';%���������Ӳ�Ͷ��������
end
end

function [h,H,el]=prmodel(rr,sats)
for n=1:length(sats)
    [r,e,el(n)]=geodist(rr,sats(n));
    h(n,1)=r; 
%     h(n,1)=r+2.4/sin(el(n)); 
    H(n,:)=[e',1];%���������Ӳ�Ͷ��������
end
end
function N =InitfloatAmb(rr,sats)
C=299792458; lam=C/1.57542E9;
for i = 1:length(sats)
    [r12,e12]=geodist(rr,sats(i));
    N(i)=r12/lam;
end
end
% temporal update of states ----------------------------------------------------
 function [x,P]=udstate(sats,x,P,rr,obs,iobs,mode,lam,slip)
% function x=udstate(sats,x,rr,obs,iobs,mode,lam)
 F=ones(length(x),1); Q=zeros(length(x),1);
if ~mode & isnan(x(1))
    x(1:3)=rr; 
    F(1:3)=0; 
    Q(1:3)=0.2; 
elseif mode
    F(1:3)=0; 
    Q(1:3)=0.5; 
    jj = find(slip(:,2));
    x(3+jj)=x(3+jj);
end
 x(3)=-0.327;
%   N =InitfloatAmb(x(1:3),sats)';
 N=obs_dd(sats,obs,iobs,2)-obs_dd(sats,obs,iobs,1)/lam;
% i=find((isnan(x(4:end))|~isnan(slip(:,1))|~isnan(slip(:,2)))&~isnan(N)); 
%  i=find((isnan(x(4:end))|slip(:,2))&~isnan(N)); 
 i=find(isnan(x(4:end))&~isnan(N)); 
 x(3+i)=N(i); 
 F(3+i)=0; 
 Q(3+i)=5;
% for j = 4:length(x)
%     k = find(i+3==j);
%     if isempty(k)
%          Q(k)=0.0001;
%     end   
% end
P=diag(F)*P*diag(F)'+diag(Q).^2;

% if ~mode & isnan(x(1))
%     x(1:3)=rr; 
% end
% % x(3)=-0.327;
% %  N =InitfloatAmb(x(1:3),sats)';
% N=obs_dd(sats,obs,iobs,2)-obs_dd(sats,obs,iobs,1)/lam;
% % i=find((isnan(x(4:end))|~isnan(slip(:,1))|~isnan(slip(:,2)))&~isnan(N)); 
% i=find((isnan(x(4:end)))&~isnan(N)); 
% x(3+i)=N(i); 
end
% double difference of observables ---------------------------------------------
%����˫��ֵ
function y=obs_dds(sref,sats,obs,iobs,ch)
y = zeros(8,1);
C=299792458; lam=C/1.57542E9;
    y1=obsdat(sref,obs,iobs,ch);
    i = find(sats==sref);
for n=1:length(sats)
    y2=obsdat(sats(n),obs,iobs,ch);
    if n == i
        continue;
    end   
    y(sats(n),1)=lam*(y1-y2);
end
    y(find(y == 0))=nan;
end
function y=obs_dd(sats,obs,iobs,ch)
% i = iobs(:,2);
% for n=1:i
%     y(n,1) = obs(n,ch);
% end
sats
for n=1:length(sats)
    y(n,1)=obsdat(sats(n),obs,iobs,ch);
end
end
function y=obsdat(sat,obs,iobs,ch)
sat
iobs(:,2)
i=find(iobs(:,2)==sat);
if ~isempty(i)
    y=obs(i(1),ch); 
else
    y=nan; 
end
end
function res = measmodel_res(rr1,N,sref,sats,lam,obs)
res = zeros(8,1);
[r11,e11]=geodist(rr1,sref);
m = length(sats);
i = find(sats==sref);
for n=1:m
    if sats(n) == i
        continue;
    end
    [r12,e12]=geodist(rr1,sats(n));
    h(sats(n))=(r11-r12)+lam*(N(sref)-N(sats(n))); 
    res(sats(n))=obs(n) - h(sats(n));
end
    res(find(res == 0)) = nan;
end
% single difference of phase model ---------------------------------------------
function [h,H,R,track]=measmodel(rr1,N,sref,sats,lam,mode,slip,track)
ii=find(slip(:,2)==1); 
[r11,e11]=geodist(rr1,sref);
h = zeros(8,1);
i = find(sats,sref);
 for n=1:length(sats)
     track(n) = track(n)+1;
    if n == i
        continue;
    end    
     Na = N(sref)-N(sats(n));
    if mode
        Na = round(N(sref)-N(sats(n)));
    end
    [r12,e12]=geodist(rr1,sats(n));
    if mode
%         if track(n)>5
%            h(sats(n),1)=(r11-r12)+lam*Na; 
%            H(sats(n),:)= e11'-e12';
%         end
           h(sats(n),1)=(r11-r12)+lam*Na; 
           H(sats(n),:)= e11'-e12';
    else
      h(sats(n),1)=(r11-r12)+lam*Na; 
      H(sats(n),[sref sats(n)])=[lam,-lam];
    end
 end
     R=(ones(length(h))+eye(length(h)))*0.006^2;
     h(find(h==0))=nan;
end
% function [h,H,R]=measmodel(rr1,N,sref,sats,lam)
% [r11,e11]=geodist(rr1,sref);
% i = find(sats,sref);
% j = 1;
% hc = 0;
% hp = 0;
% for m = 1:2
%  for n=1:length(sats)
%     if n == i
%         continue;
%     end
%     [r12,e12]=geodist(rr1,sats(n));
%     h(j,1)=(r11-r12)+lam*(N(sref)-N(sats(n))); 
%     H(j,[1:3,3+[sref sats(n)]])=[e11'-e12',[lam,-lam]];
%     j = j+1;
%  end
% if m == 1
%     hp = length(h);
%   Rp=(ones(length(h))+eye(length(h)))*0.01^2;  
% else
%      hc = length(h);
%   Rc = (ones(length(h))+eye(length(h)))^2;
% end
% end
% R = zeros(hp+hc,hp+hc);
% R(1:hp,1:hp) = Rp;
% R(hp+1:hp+hc,hp+1:hp+hc) = Rc;
% end
function [xa,Pa]=ddmat(x,P)
i = length(x);
for j = 4:i
    if ~isnan(x(j))
        break
    end
end
k = find(~isnan(x(j+1:end)));
xa = x(k)-x(j);
t = length(k);
dd = zeros(t,i);
dd(1,x(j)) = -1;
for h = 1:t
    dd(h,x(h)) = 1;
end
Pa = dd*P*dd';
end
% measurement update of states -------------------------------------------------
function [x,P]=filt(x,P,y,h,H,R,slip,mode)
i=find(~isnan(y)&~isnan(h));  
if mode
    v = y(i)-h(i);
    Ne = sqrt(sum((v-mean(v)).^2)/(length(v)));
    j =  find(abs(v-mean(v))<=4*Ne);
    hh =  find(abs(v-mean(v))>=4*Ne);
    if ~isempty(hh)
        a = 0;
    end
    H=H(i,:);
    H=H(:,1:2);
    H = H(j,:)
    R = R(i,i);
    R = R(j,j);
    K=P(1:2,1:2)*H'/(H*P(1:2,1:2)*H'+R);
    x(1:2)=x(1:2)+K*(v(j));
    P(1:2,1:2)=P(1:2,1:2)-K*H*P(1:2,1:2);
%     K=P(1:2,1:2)*H'/(H*P(1:2,1:2)*H'+R(i,i));
%     x(1:2)=x(1:2)+K*(y(i)-h(i));
%     P(1:2,1:2)=P(1:2,1:2)-K*H*P(1:2,1:2);
else
    i=find(~isnan(y)&~isnan(h)); 
    H=H(i,:);
    K=P(4:end,4:end)*H'/(H*P(4:end,4:end)*H'+R(i,i));
    x(4:end)=x(4:end)+K*(y(i)-h(i));
    P(4:end,4:end)=P(4:end,4:end)-K*H*P(4:end,4:end);
end
end
% ambiguity resolution ---------------------------------------------------------
function x=fixamb(x,P)
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
% sat_pos = [-2.827 0.3581 11.3545
%            3.1962 0.761	11.3499
%            2.7086 8.1584 11.3408
%           -3.2637 7.7569 11.3347
%            6.459 3.501  6.077
%            -0.256 9.834  6.396
%            -6.443 2.428  6.015
%            0.083 -3.771  6.484];%0421
sat_pos = [1.4118	2.8093	11.344
1.9795	4.3758	11.3412
1.1906	5.8387	11.3368
-0.1482	6.2278	11.3593
-1.4198	5.6642	11.3349
-1.9875	4.1299	11.4931
-1.239	2.6598	11.343
0.1128	2.2419	11.3654];%0423
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
function [slip,track] = detslp_dop(obs_dop,iobs,obs_pre_dop,iobs_pre,lam,track)
    DTTOL= 0.005; MAXACC =30.0;sats = 1:8;
     slip=zeros(8,2);
    tr=iobs(1,1); 
    tr_pre=iobs_pre(1,1); 
    sats_pre=iobs_pre(:,2);
    for j = 1:length(sats)
        jj = find(iobs(:,2)==j);
        jj_pre= find(iobs_pre(:,2)==j);
        slip(j,1) = j;
        if isempty(jj&jj_pre)  
            slip(j,2)=0;
            continue;
        end
       dph=obs_dop(jj,2)-obs_pre_dop(jj_pre,2);
       tt=tr-tr_pre;
%  /* cycle slip threshold (cycle) */
        thres=MAXACC*tt*tt/2.0/lam+abs(tt)*4.0;
       if abs(tt)<DTTOL
           continue;
       end
       dpt=-(obs_dop(jj,3)+obs_pre_dop(jj_pre,3))/2*tt;
%        slip(sats(j),2) = abs(dph-dpt);
%         if abs(dph-dpt)<=tt*4*sqrt(2)*0.03/lam
%             continue;                  
%         end
        if abs(dph-dpt)<=0.25
            continue;                  
        end
        slip(sats(j),2) = dph-dpt;
        track(j) = 0;
%         slip(sats(j),2) = 1;
    end
%     slip(:,slip(:,2)==0)=nan;
end
function x_mul = multipath(obs,iobs,sats)
  C=299792458; 
  lam=C/1.57542E9; 
  for i = 1:length(sats)
    j=[];
    j = find(iobs(:,2)==sats(i));
    if ~isempty(j)
    x_mul(i)=obs(j(1),1)-lam*obs(j(1),2); 
    else
    x_mul(i)=nan; 
    end
  end
  x_mul= x_mul';
end
function res = Optimalsearch(X,sref,sats,lam,obs)
  rr1 = X(1:3);
  N= X(4:end);
  count = 1;
  a = 1;
  b = 0.4;
  while 1
  for i = X(1)-a:b:X(1)+a
      for j = X(2)-a:b:X(2)+a
          rr1(1) = i;
          rr1(2) = j;
          ref = measmodel_res(rr1,N,sref,sats,lam,obs);
          cc  = find(~isnan(ref));
          LS = norm(ref(cc));
          res_f(count,:)=[LS rr1']';
          count = count+1;
      end
  end
  res_f = sortrows(res_f,1);
  if res_f(1,1) < 0.2
     break
  else
      res_f = [];
     a = a+1; 
     count = 1;
  end
  end
  res_f = sortrows(res_f,1);
  res = res_f(1:2,:);  
end
function [x_result,cycle]=LM(f,v,xk)
f = f';
j=jacobian(f,v);  %%   ��jacobian����ʽ
I=eye(2);
alpha1=0.01;  %alpha1ԽСԽ�ӽ�����ķ���
beta=10;
alpha=alpha1/beta;
k=1;
M=1e-5;
J1=subs(j,v,xk);
F1=subs(f,v,xk);
d=-inv(J1'*J1+alpha.*I)*J1'*F1;
s2=xk+d';                     %% s1Ϊ��һ�ε㣬s2Ϊ��һ�ε�����
J2=subs(j,v,s2);
F2=subs(f,v,s2);
while 1
while (sum(F2.^2))^(1/2)<(sum(F1.^2))^(1/2)
        xk=s2;
        J1=J2;
        F1=F2;
        if (sum((J1'*F1).^2))^(1/2)<=M    %%�ڴ˲������ϵĴ����������ַ����������뵽
           s3=xk;
           break;
        end
        alpha=alpha/beta;
        k=k+1;
        d=-inv(J1'*J1+I.*alpha)*J1'*F1;
        s2=xk+d';
        J2=subs(j,v,s2);
        F2=subs(f,v,s2);
end
while (sum(F2.^2))^(1/2)>=(sum(F1.^2))^(1/2)
    if (sum((J1'*F1).^2))^(1/2)<=M
        s3=xk;
        break;
    else
        alpha=alpha*beta;
        d=-inv(J1'*J1+I.*alpha)*J1'*F1;
        s2=xk+d';
        J2=subs(j,v,s2);
        F2=subs(f,v,s2);
    end
end
if (sum((J1'*F1).^2))^(1/2)<=M
    break;
end
end
end
function [x_result,k]=mulNewtonSOR(xk,N,sref,sats,lam,obs,mode)
xinit = xk;
[J1,F1] = GetJ(xk,N,sref,sats,lam,obs,mode);
I=eye(3);
alpha1=0.5;  %alpha1ԽСԽ�ӽ�����ķ���
beta=10;
alpha=alpha1/beta;
k=1;
M=1e-5;
d=-inv(J1'*J1+alpha.*I)*J1'*F1;
s2=xk+d';                     %% s1Ϊ��һ�ε㣬s2Ϊ��һ�ε�����
[J2,F2] = GetJ(s2,N,sref,sats,lam,obs,mode);
while 1
while (sum(F2.^2))^(1/2)<(sum(F1.^2))^(1/2)
        xk=s2;
        J1=J2;
        F1=F2;
        if (sum((J1'*F1).^2))^(1/2)<=M    %%�ڴ˲������ϵĴ����������ַ����������뵽
           s3=xk;
           break;
        end
        alpha=alpha/beta;
        k=k+1;
        d=-inv(J1'*J1+I.*alpha)*J1'*F1;
        s2=xk+d';
[J2,F2] = GetJ(s2,N,sref,sats,lam,obs,mode);
end
while (sum(F2.^2))^(1/2)>=(sum(F1.^2))^(1/2)
    if (sum((J1'*F1).^2))^(1/2)<=M
        s3=xk;
        break;
    else
        alpha=alpha*beta;
        d=-inv(J1'*J1+I.*alpha)*J1'*F1;
        s2=xk+d';
        [J2,F2] = GetJ(s2,N,sref,sats,lam,obs,mode);
    end
end
if (sum((J1'*F1).^2))^(1/2)<=M
    break;
end
end
%  e=1e-5;   %ͣ������
%   while (sum((J'*F).^2))^(1/2)>e %�ж�ͣ�����
% 	    d=-inv(J'*J)*J'*F;          %��������
%         xk=xk+d';                      %�µĵ�����
% 	    [J,F] = GetJ(xk,N,sref,sats,lam,obs);             %�µĵ�������ֵ������ʽ           
% 	    k=k+1;                      %����������1
%        if(k>100000)                                              %������������
%         disp('��������̫�࣬���ܲ�������');
%           return;
%        end
%   end
% f = f';
%  e=1e-5;   %ͣ������
%  cycle=0;
%  j=jacobian(f,x);   %��jacobian����ʽ
%  J=subs(j,x,xk);     %������ֵ������ʽ
%  F=subs(f,x,xk);
%  k=0;
%  while (sum((J'*F).^2))^(1/2)>e %�ж�ͣ�����
% 	    d=-inv(J'*J)*J'*F;          %��������
%         xk=xk+d';                      %�µĵ�����
% 	    J=subs(j,x,xk);              %�µĵ�������ֵ������ʽ           
%         F=subs(f,x,xk);
% 	    k=k+1;                      %����������1
%        if(k>100000)                                              %������������
%         disp('��������̫�࣬���ܲ�������');
%           return;
%        end
% end
%  while(norm(dk)>e)
%     fk=subs(f,x,xk);
%     A=subs(df,x,xk);
%     dk=-fk*A/(A.'*A);
%     Fx=f*f.'; 
%     dfx=jacobian(Fx,x);
%     Fxlan=subs(Fx,x,xk+lambda*dk);  %��cos�Ĳ�̫�����ǵ��庯�������Բ�����min������������=0�Ľ�
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%armijo�Ǿ�ȷ��������,��beta��С�Ļ��������armijo������Ч�ʣ�������ѭ��Ҳ���Լ��٣�������0.6
%     alpha=1;   %����Ҫ����ѭ�����棬�µ�ѭ���õ���alpha�ĵ���ֵ
%     beta=0.6;
%     while(subs(Fxlan,lambda,alpha)>subs(Fx,x,xk)+beta*alpha*subs(dfx,x,xk)*dk.')
%         alpha=beta*alpha;
%     end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       xk=xk+alpha*dk;
%       cycle=cycle+1;
%       if(cycle>100000)                                              %������������
%         disp('��������̫�࣬���ܲ�������');
%       return;
%     end
%  end
    x_result=xk;
end
function [H,h] = GetJ(rr1,N,sref,sats,lam,obs,mode)
[r11,e11]=geodist(rr1',sref);
 h = zeros(8,1);
i = find(sats==sref);
 for n=1:length(sats)
    if n == i
        continue;
    end
    Na = N(sref)-N(sats(n));
    if mode
        Na = round(N(sref)-N(sats(n)));
    end
    [r12,e12]=geodist(rr1',sats(n));
    if mode
      h(sats(n),1)=(r11'-r12)+lam*Na; 
      H(sats(n),:)= e11'-e12';
    else
      h(sats(n),1)=(r11'-r12)+lam*Na; 
      H(sats(n),[1:3,3+[sref sats(n)]])=[e11'-e12',[lam,-lam]];
    end
 end
 jj = find(h~=0);
 h = h(jj);
 H = H(jj,:);
end
function F = Getparam(xp,N,sref,sats,lam,obs)
sat_pos = [1.4118	2.8093	11.344
1.9795	4.3758	11.3412
1.1906	5.8387	11.3368
-0.1482	6.2278	11.3593
-1.4198	5.6642	11.3349
-1.9875	4.1299	11.4931
-1.239	2.6598	11.343
0.1128	2.2419	11.3654];
% F = zeros(8,1);
m = length(sats);
i = find(sats==sref);
% r11 =  sqrt((xp(1)-sat_pos(i,1))^2+(xp(2)-sat_pos(i,2))^2+(xp(3)-sat_pos(i,3))^2)+lam*N(sref);
r11 = sqrt(xp(1)^2+sat_pos(i,1)^2-2*sat_pos(i,1)*xp(1)+xp(2)^2+sat_pos(i,2)^2-2*sat_pos(i,2)*xp(2)...
    +(N(3)-sat_pos(i,3))^2)+lam*N(sref+3);
% sqrt((xp(1)-sat_pos(i,1))^2+(xp(2)-sat_pos(i,2))^2+(N(3)-sat_pos(i,3))^2)+lam*N(sref+3);
for n=1:m
    k = sats(n);
    if  k== i
        continue;
    end
%     r12= sqrt((xp(1)-sat_pos(n,1))^2+(xp(2)-sat_pos(n,2))^2+(N(3)-sat_pos(n,3))^2)+lam*N(sats(n)+3); 
    r12 = sqrt(xp(1)^2+sat_pos(n,1)^2-2*sat_pos(n,1)*xp(1)+xp(2)^2+sat_pos(n,2)^2-2*sat_pos(n)*xp(2)...
    +(N(3)-sat_pos(n,3))^2)+lam*N(sats(n)+3);
%     F(n)=(r11-r12)-obs(n); 
 F(n)=xp(1)^2+sat_pos(n,1)^2-2*sat_pos(n,1)*xp(1)+xp(2)^2+sat_pos(n,2)^2-obs(n);
end
    ii = find(~isnan(obs));
    F=F(ii);
end
% function xv = resdop(rr1,sats,sref,obs_dop,iobsk)
%   C=299792458; 
%   lam=C/1.57542E9; 
%  m = length(sats);
%   for n=1:m
%        j = find(iobsk==n);
%        if ~isempty(j)
%            sref = n;
%            break;
%        end
%   end
%    [r11,e11]=geodist(rr1,sref);
%     h = find(iobsk == sref);  
% 
%  xv = zeros(3,1);  
%  while 1
%      H = zeros(m,3);
%      v =  zeros(m,1);
%      for n=1:m
%       if sats(n) == sref
%         continue;
%       end
%       j = find(iobsk == n); 
%       if isempty(j)
%           continue;
%       end
%       [r12,e12]=geodist(rr1,sats(n));
%       H(sats(n),:)=e11'-e12';
%       v(sats(n))= -H(sats(n),:)*xv-lam*(obs_dop(h)-obs_dop(j));
%      end
%       jj= find(v~=0);
%       H = H(jj,:);
%       x_v = H'*H\H'*v(jj);
%       xv = xv+x_v;
%       if norm(x_v(1:2))<0.001
%       if norm(x_v(1:2))<1
%           break
%       end
%  end
% end
function ref = getrefsat(sats,iobsk,slip)
ref = [];
i = find(slip(:,2));
for n = 1:length(sats)
    if isempty(find(i==n))
    if find(iobsk(:,2) == n)
        ref = n;
        break;
    end
    end
end
if isempty(ref)
    cc= 0;
end
end
function [x,P] = restoreAmb(x,P,obsk,iobsk,sats,sref,slip,y)
 if isempty(find(slip(:,2)))
     return;
 end
   C=299792458; 
  lam=C/1.57542E9;
 F=ones(length(x),1); Q=zeros(length(x),1);
 N=obs_dd(sats,obsk,iobsk,2)-obs_dd(sats,obsk,iobsk,1)/lam;
 tmp_slip = slip(:,2);
 j = find(tmp_slip==0);
 tmp_slip(j)=nan;
 i=find(~isnan(tmp_slip)&~isnan(N)); 
 F(1:3)=0; 
 Q(1:3)=0.1;
 x(3+i)=N(i); 
 F(3+i)=0; 
 Q(3+i)=5;
 P=diag(F)*P*diag(F)'+diag(Q).^2;
 [x,P]=restore_meas(x,P,sref,sats,lam,slip,y);
end
function [x,P]=restore_meas(x,P,sref,sats,lam,slip,y)
ii=find(slip(:,2)); 
H = zeros(8,8);
[r11,e11]=geodist(x(1:3),sref);
h = zeros(8,1);
i = find(sats==sref);
 for n=1:length(sats)
    if n == i
        continue;
    end
    if isempty(find(ii == n))
        continue;
    end
     Na = x(3+sref)-x(3+sats(n));
     [r12,e12]=geodist(x(1:3),sats(n));
     h(sats(n),1)=(r11-r12)+lam*Na; 
     H(sats(n),[sref sats(n)])=[lam,-lam];
 end
     R=(ones(length(h))+eye(length(h)))*0.006^2;
     h(find(h==0))=nan;
     mode = 0;
     [x,P]=filt(x,P,y,h,H,R,slip,mode);
end
function isused = Validitytest(isused,res)
  Normalerror = std(res);
  i =  find(res>4*Normalerror);
  isused(i) = 0;
end