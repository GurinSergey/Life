/******************************************************************************
   ��� 䠩��.:       ProcInit.mac
   �����祭��:       ������� ����⠭� ��� ����ᮢ
   ���......:       22.08.2008
   ����.....:       �⠤��� ����ᠭ��
******************************************************************************/

//---- [�㬥��� ����� ��� �㭪樨 ᮧ����� ���] ----//
const crtAccountFldAccount     = 0;
const crtAccountFldChapter     = 1;
const crtAccountFldBranch      = 2;
const crtAccountFldDepartment  = 3;
const crtAccountFldClient      = 4;
const crtAccountFldOper        = 5;
const crtAccountFldAccType     = 6;
const crtAccountFldAccUserType = 7;
const crtAccountFldAccName     = 8;
const crtAccountFldPackMode    = 9;
const crtAccountFldOpenDate    = 10;


//---- [�㬥��� ����� ��� �㭪樨 ����䨪�樨 ���] ----//
const updAccountFldAccount       = 0;
const updAccountFldChapter       = 1;
const updAccountFldOverdraft     = 2;
const updAccountFldLimit         = 3;
const updAccountFldOperationDate = 4;
                          

//---- [�㬥��� ����� ��� �㭪樨 ������� ���] ----//
const clsAccountFldAccount     = 0;
const clsAccountFldChapter     = 1;
const clsAccountFldCloseDate   = 2;


//---- [�㬥��� ����� ��� �㭪樨 ��⠭���� ���祭�� ��⥣�ਨ] ----//
const setCategoryFldObjectType  = 0;
const setCategoryFldObjectID    = 1;
const setCategoryFldGroupID     = 2;
const setCategoryFldAttrID      = 3;
const setCategoryFldGeneral     = 4;

//---- [�㬥��� ����� ��� �㭪樨 㤠����� ���祭�� ��⥣�ਨ] ----//
const delCategoryFldObjectType  = 0;
const delCategoryFldObjectID    = 1;
const delCategoryFldGroupID     = 2;
const delCategoryFldAttrID      = 3;

//---- [�㬥��� ����� ��� �㭪樨 ��⠭���� ���祭�� ��⥣�ਨ] ----//
const setNoteFldObjectType  = 0;
const setNoteFldObjectID    = 1;
const setNoteFldNoteKind    = 2;
const setNoteFldNoteValue   = 3;


//---- [�㬥��� ����� ��� �㭪樨 㤠����� ���祭�� ��⥣�ਨ] ----//
const delNoteFldObjectType  = 0;
const delNoteFldObjectID    = 1;
const delNoteFldNoteKind    = 2;     


//---- [�����䨪���� ⨯�� �� ⠡��� dnotekind_dbt] ----//
const FT_INT         = 0;
const FT_LONG        = 1;
const FT_FLOAT       = 2;
const FT_FLOATG      = 3;
const FT_DOUBLE      = 4;
const FT_DOUBLEG     = 5;
const FT_DOUBLEM     = 6;
const FT_STRING      = 7;
const FT_SNR         = 8;
const FT_DATE        = 9;
const FT_TIME        = 10;
const FT_SHTM        = 11;          
const FT_CHR         = 12;
const FT_UCHR        = 13;
const FT_LDMON       = 14;
const FT_LDMONR      = 15;
const FT_DOUBLER     = 16;
const FT_LDOUBLE     = 17;
const FT_NUMSTR      = 18;
const FT_DECIMAL     = 19;
const FT_MONEY_OLD   = 20;
const FT_LMONEY_OLD  = 21;
const FT_MONEYR_OLD  = 22;
const FT_LMONEYR_OLD = 23;
const FT_BINARY      = 24;
const FT_NUMERIC     = 25;


//- [�㭪�� ᮧ����� ������] -//
const crtClientFldLegalForm   = 0;
const crtClientFldShortName   = 1;
const crtClientFldFullName    = 2;
const crtClientFldAddName     = 3;
const crtClientFldLastName    = 4;
const crtClientFldFirstName   = 5;
const crtClientFldSecondName  = 6;
const crtClientFldBirthDate   = 7;
const crtClientFldBirthPlace  = 8;
const crtClientFldIsMale      = 9;
const crtClientFldNationality = 10;
const crtClientFldIsEmployer  = 11;
const crtClientFldWorkPlace   = 12;
const crtClientFldOKPO        = 13;
const crtClientFldCountry     = 14;
const crtClientFldSuperiorID  = 15;
const crtClientFldCharterDate    = 16;
const crtClientFldCapitalFI      = 17;
const crtClientFldDeclareCapital = 18;
const crtClientFldRealCapital    = 19;
const crtClientFldLatName        = 20;

                          

//- [�㭪�� ����䨪�樨 ������] -//
const updClientFldPartyID     = 0;
const updClientFldShortName   = 1;
const updClientFldFullName    = 2;
const updClientFldAddName     = 3;
const updClientFldLastName    = 4;
const updClientFldFirstName   = 5;
const updClientFldSecondName  = 6;
const updClientFldBirthDate   = 7;
const updClientFldBirthPlace  = 8;
const updClientFldIsMale      = 9;
const updClientFldNationality = 10;
const updClientFldIsEmployer  = 11;
const updClientFldWorkPlace   = 12;
const updClientFldOKPO        = 13;
const updClientFldCountry     = 14;
const updClientFldSuperiorID  = 15; 
const updClientFldCharterDate    = 16;
const updClientFldCapitalFI      = 17;
const updClientFldDeclareCapital = 18;
const updClientFldRealCapital    = 19;
const updClientFldLatName        = 20;



//- [�㭪�� 㤠����� ������] -//
const delClientFldPartyID     = 0;


//- [�㭪�� ���⠭���� ������ �� ���㦨�����] -//
const setClientServiceFldPartyID    = 0;
const setClientServiceFldServKind   = 1;
const setClientServiceFldOper       = 2;
const setClientServiceFldStartDate  = 3;
const setClientServiceFldDepartment = 4;
const setClientServiceFldBranch     = 5;


//- [�㭪�� ���� ������ � ���㦨�����] -//
const delClientServiceFldPartyID    = 0;
const delClientServiceFldServKind   = 1;


//- [�㭪�� ᮧ����� ���� ������] -//
const setClientCodeFldPartyID      = 0;
const setClientCodeFldCodeKind     = 1;
const setClientCodeFldCodeValue    = 2;


//- [�㭪�� 㤠����� ���� ������] -//
const delClientCodeFldPartyID      = 0;
const delClientCodeFldCodeKind     = 1;


//- [�㭪�� ᮧ����� ���� ������] -//
const setClientAddressFldPartyID        = 0;
const setClientAddressFldAddressType    = 1;
const setClientAddressFldCountry        = 2;
const setClientAddressFldAddress        = 3;
const setClientAddressFldPhoneNumber    = 4;
const setClientAddressFldPhoneNumberAd  = 5;
const setClientAddressFldFaxNumber      = 6;
const setClientAddressFldEMail          = 7;
const setClientAddressFldMobilePhone    = 8;
// KS 05.03.2011 ������� ���� ����
const setClientAddressFldCodeDistrict   = 9;
const setClientAddressFldCodePlace      = 10;
const setClientAddressFldCodeProvince   = 11;
const setClientAddressFldCodeRegion     = 12;
const setClientAddressFldCodeStreet     = 13;
const setClientAddressFldDistrict       = 14;
const setClientAddressFldFlat           = 15;
const setClientAddressFldHouse          = 16;
const setClientAddressFldMobileProvider = 17;
const setClientAddressFldNumCorps       = 18;
const setClientAddressFldPlace          = 19;
const setClientAddressFldPostIndex      = 20;
const setClientAddressFldProvince       = 21;
const setClientAddressFldRegion         = 22;
const setClientAddressFldRegionNumber   = 23;
const setClientAddressFldRS_Mail_Country= 24;
const setClientAddressFldRS_Mail_Node   = 25;
const setClientAddressFldRS_Mail_Region = 26;
const setClientAddressFldStreet         = 27;
const setClientAddressFldTelegraph      = 28;
const setClientAddressFldTelexNumber    = 29;
const setClientAddressFldTerritory      = 30;


//- [�㭪�� 㤠����� ���� ������] -//
const delClientAddressFldPartyID       = 0;
const delClientAddressFldAddressType   = 1;


//- [�㭪�� ᮧ����� ॣ����樨 ������] -//
const setClientRegDocFldPartyID      = 0;
const setClientRegDocFldRegPartyKind = 1;
const setClientRegDocFldRegDocKind   = 2;
const setClientRegDocFldRegPartyID   = 3;
const setClientRegDocFldStartDate    = 4;
const setClientRegDocFldSeries       = 5;
const setClientRegDocFldNumber       = 6;
const setClientRegDocFldDocDate      = 7;
const setClientRegDocFldIsMain       = 8;


//- [�㭪�� 㤠����� ॣ����樨 ������] -//
const delClientRegDocFldPartyID      = 0;
const delClientRegDocFldRegPartyKind = 1;
const delClientRegDocFldRegDocKind   = 2;
                                         

//- [�㭪�� ���������� ���㤭���] -//
const setClientOfficerFldPartyID        = 0;
const setClientOfficerFldPersonID       = 1;
const setClientOfficerFldIsFirstPerson  = 2;
const setClientOfficerFldIsSecondPerson = 3;
const setClientOfficerFldPost           = 4;
const setClientOfficerFldDateFrom       = 5;
const setClientOfficerFldDateTo         = 6;

//- [�㭪�� 㤠����� ���㤭���] -//
const delClientOfficerFldPartyID      = 0;
const delClientOfficerFldPersonID     = 1;
 

//- [�㭪�� ���������� ���㬥��] -//
const setClientPaperFldPartyID    = 0;
const setClientPaperFldPaperKind  = 1;
const setClientPaperFldSeries     = 2;
const setClientPaperFldNumber     = 3;
const setClientPaperFldIssuedDate = 4;
const setClientPaperFldIssuer     = 5;
const setClientPaperFldIssuerCode = 6;
const setClientPaperFldIsMain     = 7;


//- [�㭪�� 㤠����� ���㬥��] -//
const delClientPaperFldPartyID    = 0;
const delClientPaperFldPaperKind  = 1;


//-[�㭪�� �믮������ �஢���� � 蠣� ����樨]
const crtCarryFldDocKind        = 0;
const crtCarryFldPaymentID      = 1;
const crtCarryFldOperationID    = 2;
const crtCarryFldOper           = 3;
const crtCarryFldDepartment     = 4;  
const crtCarryFldVSP            = 5;  
const crtCarryFldFIID           = 6;  
const crtCarryFldValueDate      = 7;
const crtCarryFldChapter        = 8;
const crtCarryFldPayerAccount   = 9;
const crtCarryFldReceiverAccount= 10;
const crtCarryFldGround         = 11;
const crtCarryFldSum            = 12;
const crtCarryFldPack           = 13;   
const crtCarryFldNumDoc         = 14;
const crtCarryFldNumCarry       = 15;
const crtCarryFldKindOper       = 16;
const crtCarryFldShifrOper      = 17;




//-[�㭪�� �믮������ �⪠� �஢����]

const crtCarryFldPayment_ID     = 0;
const crtCarryFldBkOper         = 1;


//-[�㭪�� �믮������ 蠣� ����樨]

const crtOperationPaymentID     = 0;
const crtOperationDocKind       = 1;
const crtOperationPackID        = 2;