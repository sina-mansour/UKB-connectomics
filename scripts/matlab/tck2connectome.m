function [c,unassigned]=tck2connectome(f_ends,f_atlas,varargin)

if strcmp(varargin{1},'radius') || strcmp(varargin{1},'Radius')
    Radius=varargin{2}; 
else
    Radius=4; 
end

%Read endpoints
x=readNPY(f_ends); 
x=half.typecast(x); 

N=size(x,1); %number of streamlines

%Read parcellation
hdr=niftiinfo(f_atlas);
v=niftiread(f_atlas)*hdr.MultiplicativeScaling;
ind_atlas=setdiff(unique(v(:)),0); 
J=length(ind_atlas); %number of nodes

%Transform endpoints from mm to voxel coordinates 
y1=[squeeze(x(:,1,:)),ones(N,1)]*inv(hdr.Transform.T); 
y2=[squeeze(x(:,2,:)),ones(N,1)]*inv(hdr.Transform.T);  
y1=y1(:,1:3); y2=y2(:,1:3); 
clear hdr x

%Compute voxel index for endpoints, R suffix indicates rounded coordinates
y1=y1+1; y2=y2+1; %count from 1, not 0
y1R=round(y1); y2R=round(y2); %(0.5,0.5,0.5) is centre of voxel at (0,0,0) 
y1R=sub2ind(size(v),y1R(:,1),y1R(:,2),y1R(:,3)); 
y2R=sub2ind(size(v),y2R(:,1),y2R(:,2),y2R(:,3)); 

ind1=v(y1R); ind2=v(y2R); %index of atlas region in which endpoint resides
ind=~~(~~ind1.*~~ind2); %1 if both endpoints reside in regions, 0 otherwise
%Build connectivity matrix
c=accumarray([ind1(ind),ind2(ind)],ones(sum(ind),1),[J,J]); 

%Process endpoints that do not reside in an atlas region

%Image classifying endpoints
t=zeros(size(v)); t(y1R)=0.5; t(y2R)=0.5;  
img=~~v; img=img+t; img=img*2; 
%1: voxel comprises endpoint but endpoint is not in atlas
%2: voxel is in atlas but does not comprise endpoint
%3: voxel comprises endpoint and is in atlas

if Radius>0
    %Radius heuristic to assign streamlines outside atlas
    %Streamlines with one or both ends residing outside atlas
    %Define spherical kernel
    nhood=zeros(Radius*2+1,Radius*2+1,Radius*2+1);
    kernel=[]; cnt=0;
    for i=-Radius:Radius
        for j=-Radius:Radius
            for k=-Radius:Radius
                if sqrt(sum(i^2+j^2+k^2))<=Radius
                    cnt=cnt+1;
                    nhood(i+Radius+1,j+Radius+1,k+Radius+1)=1;
                    kernel=[kernel;[i,j,k]];
                    dist(cnt)=sqrt(sum(i^2+j^2+k^2));
                end
            end
        end
    end

    %Dilate atals using the spherical kernel
    vdil=imdilate(~~v,nhood);
    vdil=vdil.*~v; %remove voxels in atlas from dilated image
    vdil=vdil.*(img==1); %remove voxels with no endpoints from dilated image
    %Note: img==1 are voxels comprising endpoint but endpoint is not in atlas

    ind_dil=find(vdil); %find voxels for which radius search will be performed
    vdil_ref=zeros(size(vdil));
    vdil_ref(ind_dil)=1:length(ind_dil); %reference image for quicker look up
    [xd,yd,zd]=ind2sub(size(v),ind_dil);
    vmin=cell(length(ind_dil),1); %store list of min distance voxels
    for i=1:length(ind_dil)
        coor=repmat([xd(i),yd(i),zd(i)],size(kernel,1),1)+kernel;
        ind_coor=sub2ind(size(v),coor(:,1),coor(:,2),coor(:,3));
        %identify neighbouring voxels that are in atlas and then store them as
        %their distance from the kernel centre
        tmp=(~~v(ind_coor)).*dist'; %0 indicates that the voxel is not in the atlas
        tmp=(min(tmp(tmp>0))==tmp); %find list of min distance voxels
        %there may be multiple min distance voxels
        [xx,yy,zz]=ind2sub(size(v),ind_coor(tmp));
        vmin{i}=[xx,yy,zz];
        %testing
        %v(vmin{i}(1,1),vmin{i}(1,2),vmin{i}(1,3))
        %pause
    end

    unassigned=0; frst=0;
    ind=find(~ind); %1 if one or both endpoints not in atlas
    for i=1:length(ind)
        if v(y1R(ind(i)))
            u1=v(y1R(ind(i))); %first endpoint is in the atlas
        elseif vdil(y1R(ind(i))) %otherwise look in dilated image
            n=vdil_ref(y1R(ind(i))); %index into ind_dil
            %Multiple voxels in the neighbourhood may have the same min
            %distance to a voxel in the atlas. Use the exact voxel coordinate
            %to determine a unique minimum
            [~,i_min]=min(sum((vmin{n}-repmat(y1(ind(i),:),size(vmin{n},1),1)).^2,2));
            u1=v(vmin{n}(i_min,1),vmin{n}(i_min,2),vmin{n}(i_min,3));
        else
            u1=[]; %cannot assign, outside radius
        end
        if ~isempty(u1)
            if v(y2R(ind(i)))
                u2=v(y2R(ind(i)));
            elseif vdil(y2R(ind(i)))
                n=vdil_ref(y2R(ind(i))); %index into ind_dil
                [~,i_min]=min(sum((vmin{n}-repmat(y2(ind(i),:),size(vmin{n},1),1)).^2,2));
                u2=v(vmin{n}(i_min,1),vmin{n}(i_min,2),vmin{n}(i_min,3));
            else
                u2=[];
            end
        end
        if ~isempty(u1) && ~isempty(u2)
            c(u1,u2)=c(u1,u2)+1; %increment count
        else
            unassigned=unassigned+1; %count of unassigned streamlines
        end
        show_progress(i,length(ind),frst); frst=1;
    end
end

%symmetrize
c=triu(c)+tril(c,-1)'; c=c+c';


