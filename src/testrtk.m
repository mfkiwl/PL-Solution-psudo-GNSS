% function testrtk
%  [file path]=uigetfile('C:\Users\jingqu\Desktop\α����˫����α��-�ز���λ�����\*.*','ѡ������')
clear all;
clc;
[file1 path1]=uigetfile('*.*','ѡ������');
files1=strcat(path1,file1);
% files='C:\Users\jingqu\Desktop\α����˫����α��-�ز���λ�����\˫���߰����\һ��˫���߰��ź�.obs';
[obs,iobs,time]=readrnx(files1,1);
save obs.mat obs;
save iobs.mat iobs;

[xs,xres] =ppp_SD(time,obs,iobs,1,2);
save xs.mat xs;
% [file2 path2]=uigetfile('*.*','ѡ������') 
% files2=strcat(path2,file2);
% files='C:\Users\jingqu\Desktop\α����˫����α��-�ز���λ�����\˫���߰����\һ��˫���߰��ź�.obs';
% [obs2,iobs2]=readrnx(files2,2);
% obs=[obs1;obs2];
% iobs=[iobs1;iobs2];
% [xp,xs,xf]=rtkdemo(t0,time,rref,obs,iobs,0)
[m,n]=size(xres);
t = 1:m;
figure(4);
for j=1:n
    plot(t,xres(:,j),'LineWidth',3);
        hold on
end
% axis([1 200 -0.5 0.5]);
ylabel('residual','fontsize',20);
title('obs_res');
fid=fopen('output.txt', 'wt');
fid1=fopen('output1.txt', 'wt');
for i = 1 : m
	fprintf(fid, '%g\t', xs(i, :));
	fprintf(fid, '\n');
    fprintf(fid1, '%g\t', xres(i, :));
	fprintf(fid1, '\n');
end
fclose(fid);
fclose(fid1);

% [xs,xres] =ppp_SD(time,obs,iobs,1,2);
testobs(time,obs,iobs);
% save xs.mat xs;
% save xres.mat xres;
% % [file2 path2]=uigetfile('*.*','ѡ������') 
% % files2=strcat(path2,file2);
% % files='C:\Users\jingqu\Desktop\α����˫����α��-�ز���λ�����\˫���߰����\һ��˫���߰��ź�.obs';
% % [obs2,iobs2]=readrnx(files2,2);
% % obs=[obs1;obs2];
% % iobs=[iobs1;iobs2];
% % [xp,xs,xf]=rtkdemo(t0,time,rref,obs,iobs,0)
% [m,n]=size(xres);
% t = 1:m;
% figure(4);
% for j=1:n
%     plot(t,xres(:,j),'LineWidth',3);
%         hold on
% end
% % axis([1 200 -0.5 0.5]);
% ylabel('residual','fontsize',20);
% title('obs_res');
% fid=fopen('output.txt', 'wt');
% fid1=fopen('output1.txt', 'wt');
% for i = 1 : m
% 	fprintf(fid, '%g\t', xs(i, :));
% 	fprintf(fid, '\n');
%     fprintf(fid1, '%g\t', xres(i, :));
% 	fprintf(fid1, '\n');
% end
% fclose(fid);
% fclose(fid1);
