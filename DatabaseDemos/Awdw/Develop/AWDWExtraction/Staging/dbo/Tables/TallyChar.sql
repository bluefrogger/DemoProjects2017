CREATE TABLE [dbo].[TallyChar]
(
	nb int not null
	,constraint pk_TallyChar_nb primary key nonclustered (nb)
	,ch char null
)
