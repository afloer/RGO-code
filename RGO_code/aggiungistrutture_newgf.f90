program aggiungi
implicit none

integer(kind=16) :: natom, ncandidates, nold, bandiera, coincidenza, prova, nmodesmax, nmodesmaxl
character(len=102), dimension(:), allocatable :: path1
character(len=32) :: lungo, lungo2
character(len=36) :: lungo3

integer(kind=16) :: ii, ij

integer(kind=16), dimension(:,:), allocatable :: modo
real*8, dimension(:,:), allocatable :: energy
character(len=1), dimension(:), allocatable :: analyzed, analyzedbis
integer(kind=16), dimension(:), allocatable :: structno, nvicini, structnobis, nvicinibis
real*8, dimension(:,:), allocatable :: energy2, energy2bis
integer(kind=16), dimension(:,:), allocatable :: vicini, vicinibis
real*8, dimension(:,:), allocatable :: viciniTS, viciniTSbis



open(unit=101, file='candidatesort', status='old')


read(*,*) natom, ncandidates, nold

allocate(modo(1:ncandidates,1:2))
allocate(energy(1:ncandidates,1:5))
allocate(path1(1:ncandidates))

do ii=1,ncandidates
  !read(101,'(i9,1x,i9,1x,f12.7,1x,f11.5,4x,f11.5,4x,f11.5,1x,f15.10,1x,a33)') modo(ii,1:2), energy(ii,1:5), path1(ii)
  read(101,'(i32,1x,i32,1x,f12.8,1x,f12.5,4x,f12.5,4x,f12.5,1x,f19.11,1x,a102)') modo(ii,1:2), energy(ii,1:5), path1(ii)
enddo

close(101)


nmodesmax=6*natom-12
nmodesmaxl=500


allocate(analyzed(1:nold))
allocate(structno(1:nold), nvicini(1:nold))
allocate(energy2(1:nold,1:4))
allocate(vicini(1:nold,1:nmodesmaxl))
allocate(viciniTS(1:nold,1:nmodesmaxl))
analyzed='N'
structno=-1
nvicini=-1
energy2=2.0
vicini=-1
viciniTS=2.0
open(unit=102, file='../Structure_file.txt', status='old')
open(unit=103, file='debug', status='replace')
do ij=1,nold
  read(102,*) analyzed(ij), structno(ij), energy2(ij,:), nvicini(ij), vicini(ij,1:nvicini(ij)), viciniTS(ij,1:nvicini(ij))
enddo
close(102)


prova=-1
do ij=1,nold
  if (structno(ij).eq.modo(1,1)) then
    prova=ij
  endif
enddo
!prova = findloc(structno,modo(1,1), dim=1)

do ii=1,ncandidates
  bandiera=1
  do ij=1,nold
    if (abs(energy2(ij,1)-energy(ii,1)).lt.(0.0001)) then
      if (abs(energy2(ij,2)-energy(ii,2)).lt.(8)) then
        if (abs(energy2(ij,3)-energy(ii,3)).lt.(8)) then
          if (abs(energy2(ij,4)-energy(ii,4)).lt.(8)) then
            bandiera=0
            coincidenza=structno(ij)
            exit
          endif
        endif
      endif
    endif
  enddo 
  nvicini(prova) = nvicini(prova) + 1
  if (bandiera.eq.0) then
    vicini(prova,nvicini(prova))=coincidenza
  else
    vicini(prova,nvicini(prova))=modo(ii,1)*nmodesmax*2+modo(ii,2)
  endif
  viciniTS(prova,nvicini(prova))=energy(ii,5)
  if (bandiera.eq.1) then
    nold=nold+1
    !fai la stringa giusta
    write(lungo,'(i2)') natom+2
    write(lungo2,'(i32.32)') modo(ii,1)*2*nmodesmax+modo(ii,2)
    !write(lungo3,'(A)') lungo2 // ".xyz"
    !!write(*,*) "tail -n " // trim(adjustl(lungo)) // " " //  path1(ii) &
    !!                     &// "> ../To_be_analyzed/" // trim(adjustl(lungo2)) // ".xyz" 
    !!stop
    call EXECUTE_COMMAND_LINE("tail -n " // trim(adjustl(lungo)) // " " //  path1(ii) &
                         &// "> ../To_be_analyzed/" // trim(adjustl(lungo2)) // ".xyz")
    allocate(analyzedbis(1:nold))
    allocate(structnobis(1:nold), nvicinibis(1:nold))
    allocate(energy2bis(1:nold,1:4))
    allocate(vicinibis(1:nold,1:nmodesmaxl))
    allocate(viciniTSbis(1:nold,1:nmodesmaxl))
    analyzedbis(1:nold-1)=analyzed(:)
    analyzedbis(nold)='N'
    structnobis(1:nold-1)=structno(:)
    structnobis(nold)=modo(ii,1)*2*nmodesmax+modo(ii,2)
    energy2bis(1:nold-1,1:4)=energy2(:,1:4)
    energy2bis(nold,1:4)=energy(ii,1:4)
    nvicinibis(1:nold-1)=nvicini(:)
    nvicinibis(nold)=0
    vicinibis(1:nold-1,1:nmodesmaxl)=vicini(1:nold,1:nmodesmaxl)
    viciniTSbis(1:nold-1,1:nmodesmaxl)=viciniTS(1:nold,1:nmodesmaxl)
    deallocate(analyzed, structno, nvicini, energy2, vicini, viciniTS)
    allocate(analyzed(1:nold))
    allocate(structno(1:nold), nvicini(1:nold))
    allocate(energy2(1:nold,1:4))
    allocate(vicini(1:nold,1:nmodesmaxl))
    allocate(viciniTS(1:nold,1:nmodesmaxl))
    analyzed(:)=analyzedbis(:)
    structno(:)=structnobis(:)
    nvicini(:)=nvicinibis(:)
    energy2(:,:)=energy2bis(:,:)
    vicini(:,:)=vicinibis(:,:)
    viciniTS(:,:)=viciniTSbis(:,:)
    deallocate(analyzedbis, structnobis, nvicinibis, energy2bis, vicinibis, viciniTSbis)
  endif
enddo

open(unit=102, file='../Structure_file.txt', status='replace')
analyzed(prova)='Y'
do ij=1,nold
  write(102,*) analyzed(ij), structno(ij), energy2(ij,:), nvicini(ij), vicini(ij,1:(nvicini(ij))), viciniTS(ij,1:(nvicini(ij)))
enddo
close(102)

endprogram aggiungi
