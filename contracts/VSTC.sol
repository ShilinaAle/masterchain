pragma solidity ^0.4.24;

import "./Ownable.sol";

contract StorageHash { //Здесь хранятся все справки

    mapping(bytes32 => CertificateStore) public allCertificate; // хешСправки => информация по справке
    
    struct CertificateStore {
        address addrOrganization; // адресс контракта, вызавшего справку
        uint idTemplate; // номер шаблона в даной организации
        uint idCertificate; // регистрационный номер справки по данному шаблону
    }
    
    function addCertificateStore(uint _idTemplate,
        uint _idCertificate,
        bytes32 _certificateHash,
        string _dataArray) external payable {
        allCertificate[_certificateHash] = 
        CertificateStore(msg.sender, _idTemplate, _idCertificate);  // регистрация в хранилище новой справки
    }
    
    function getCertificate(bytes32 _certificateHash) 
    public returns( string dataArray,   // данные полей для заполнения шаблона справки
        uint amountField,               // количество полей шаблона      
        bytes32 certificateHash,        // хеш данных
        address addrOrganization,       // адрес организации, добавившей справку
        address addrToOrganization,     // адрес организации, запросившей справку (если есть)
        string nameOfOrganization,      // название организации
        uint timeOfCreate,              // время создания справки
        uint timeOfAction,              // срок действия справки
        string nameOfTemplate,          // название шаблона справки
        bool isExist) {                 // действительность 
        CertificateStore tempCertificate = allCertificate[_certificateHash];
        addrOrganization = tempCertificate.addrOrganization;
        uint tidCerteficate = tempCertificate.idCertificate;
        Organization tempOrganization = Organization(addrOrganization);
        nameOfOrganization = tempOrganization.getInfoOrganization();
        (timeOfAction, nameOfTemplate, amountField) = tempOrganization.getInfoTemplate(tempCertificate.idTemplate);
        (timeOfCreate, , , , isExist) =  tempOrganization.getInfoCertificate(tidCerteficate);
        (, addrToOrganization, certificateHash, dataArray, ) =  tempOrganization.getInfoCertificate(tidCerteficate);
    }
}



contract FactoryOrganization is Ownable {               // добавлять новые организации может только администратор системы
    address public storageAddr;                         // хранение всех справок
    address public verificationAddr;                    // адрес контракта с верифицированными шаблонами
    address fish = 0x0;
    address owner;                                      // главный административный узел
    mapping(address => address) public organizations;   // NodeAddress => ContractAdress
    
    constructor() public {
        owner = msg.sender;
        storageAddr = address(new StorageHash());
        verificationAddr = address(new VerificationTemplate());
    }
    
    function createOrganization(address _owner, string _nameOfOrganization) 
    onlyOwner public returns(address)                   // добавление новой организации
    {
        organizations[_owner] = 
        address(new Organization(_owner, storageAddr,verificationAddr, _nameOfOrganization));
        return address(organizations[_owner]);
    }
    
    function getMyOrhanization() public returns(bool exist, address getAddressOrganization) {
        exist = false;
        getAddressOrganization = organizations[msg.sender];
        if (getAddressOrganization != fish)
        {
            exist = true;
        }
    }
}

contract VerificationTemplate is Ownable                // верифицированные шаблоны
{
    uint indexTemplate = 0;
    
    struct StorageTemplate {
        address OrganizationAddr;                       // организации
        bool confirmed;                                 // действительность шаблона
    }
    
    mapping(uint => StorageTemplate) verifications;     // шаблон => (создатель, действительность)
    mapping(address => bool) admins;                    // администраторы
    
    function getIndexTemplate() public payable returns(uint) {      // добавление нового шаблона
        verifications[indexTemplate] = StorageTemplate(msg.sender, false);  // и присвоение ему индекса
        return indexTemplate++;
    }
    
    function confirm(uint indexTemp) public {           // подтверждение верификации
        require(admins[msg.sender]);
        StorageTemplate temp = verifications[indexTemp];
        temp.confirmed = true;
        verifications[indexTemp] = temp;
    }
    
    function addAdmin(address _adminAddr) onlyOwner {   // добавление администратора
        admins[_adminAddr] = true;
    }
    
    function banAdmin(address _adminAddr) onlyOwner {   // удаление администратора
        delete admins[_adminAddr];
    }
    
}

contract Organization {
    string nameOfOrganization;      // название организации
    address owner;                  // нода владельца
    address storageAddr;            // адресс контракта для архива
    address verificationAddr;       // адресс для верификации шаблонов
    address fish = 0x0;

    mapping(address => bool) nodesOfOrganization; // ноды оргнанизации
    mapping(uint => Template) templates; // idTemplate => Template шаблоны
    mapping(uint => Certificate) certificates; // idCertificate => Certificate сертификаты

    uint amountCertificate = 0;     // индексирование справок
    
    constructor(address _owner, address _storageAddr, address _verificationAddr, string _nameOfOrganization ) public payable {
        nameOfOrganization = _nameOfOrganization;
        owner = _owner;
        storageAddr = _storageAddr;
        verificationAddr = _verificationAddr;
        nodesOfOrganization[owner] = true;
    }
    
      modifier onlyMyNode() {
    require(nodesOfOrganization[msg.sender]);
    _;
  }
    
    struct Template {
        uint idTemplate;
        uint timeOfAction;      // срок действия
        string nameOfTemplate;  // название
        uint amountField;       // количество полей для заполнения в шаблоне
    }
    
    struct Certificate {
        uint idCertificate;
        uint idTemplate;
        address addrToOrganization; // кому предоставлена (если организация зарегистрирована в системе)
        uint timeOfCreate;          //время создания+
        bytes32 certificateHash;
        string dataArray;           // строка с полями для заполнения в шаблоне
    }
    
    function getInfoOrganization() public payable returns(string ) {
        return (nameOfOrganization);
    }
    
        function getInfoTemplate(uint _idTemplate) public payable returns( uint timeOfAction,
        string nameOfTemplate,
        uint amountField) {
        timeOfAction = templates[_idTemplate].timeOfAction;
        nameOfTemplate = templates[_idTemplate].nameOfTemplate;
        amountField = templates[_idTemplate].amountField;
    }
    
        function getInfoCertificate(uint _idCertificate) public payable returns(
        uint timeOfCreate,
        address addrToOrganization,
        bytes32 certificateHash,
        string dataArray,
        bool isExist) {
       Certificate myCertificate = certificates[_idCertificate];
       uint timeOfAction = templates[myCertificate.idTemplate].timeOfAction;
       timeOfCreate = myCertificate.timeOfCreate;
       certificateHash = myCertificate.certificateHash;
       dataArray = myCertificate.dataArray;
       addrToOrganization = myCertificate.addrToOrganization;
       isExist = true;
        if (now > (myCertificate.timeOfCreate + timeOfAction)) //проверка на действительность
        {
            isExist = false;
        }
    }
    
    function addTemplate(uint _timeOfAction, string _nameOfTemplate, uint _amountField) onlyMyNode public returns(uint) {
        VerificationTemplate tempVerificationTemplate = VerificationTemplate(verificationAddr);
        uint idTemplate = tempVerificationTemplate.getIndexTemplate();
        templates[idTemplate] = Template( idTemplate,_timeOfAction, _nameOfTemplate, _amountField);
        return idTemplate;
    }
    
    function addCertificate(uint _idTemplate, address _addrToOrganization, bytes32 _certificateHash, string _dataArray) 
    onlyMyNode public {
        require(storageAddr != fish);
        certificates[amountCertificate] = 
        Certificate(amountCertificate, _idTemplate, _addrToOrganization, now, _certificateHash, _dataArray);
        StorageHash tempStore = StorageHash(storageAddr);
        tempStore.addCertificateStore(_idTemplate, amountCertificate, _certificateHash, _dataArray);
        amountCertificate++;
    }
    
    function addNode(address _newNode) public {
        require(owner == msg.sender);
        nodesOfOrganization[_newNode] = true;
    }
    
    function banNode(address _banNode) public {
        require(owner == msg.sender);
        nodesOfOrganization[_banNode] = true;
    }
}
