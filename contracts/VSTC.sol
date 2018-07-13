pragma solidity ^0.4.24;

import "./Ownable.sol";

contract StorageHash { //����� �������� ��� �������

    mapping(bytes32 => CertificateStore) public allCertificate; // ���������� => ���������� �� �������
    
    struct CertificateStore {
        address addrOrganization; // ������ ���������, ��������� �������
        uint idTemplate; // ����� ������� � ����� �����������
        uint idCertificate; // ��������������� ����� ������� �� ������� �������
    }
    
    function addCertificateStore(uint _idTemplate,
        uint _idCertificate,
        bytes32 _certificateHash,
        string _dataArray) external payable {
        allCertificate[_certificateHash] = 
        CertificateStore(msg.sender, _idTemplate, _idCertificate);  // ����������� � ��������� ����� �������
    }
    
    function getCertificate(bytes32 _certificateHash) 
    public returns( string dataArray,   // ������ ����� ��� ���������� ������� �������
        uint amountField,               // ���������� ����� �������      
        bytes32 certificateHash,        // ��� ������
        address addrOrganization,       // ����� �����������, ���������� �������
        address addrToOrganization,     // ����� �����������, ����������� ������� (���� ����)
        string nameOfOrganization,      // �������� �����������
        uint timeOfCreate,              // ����� �������� �������
        uint timeOfAction,              // ���� �������� �������
        string nameOfTemplate,          // �������� ������� �������
        bool isExist) {                 // ���������������� 
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



contract FactoryOrganization is Ownable {               // ��������� ����� ����������� ����� ������ ������������� �������
    address public storageAddr;                         // �������� ���� �������
    address public verificationAddr;                    // ����� ��������� � ����������������� ���������
    address fish = 0x0;
    address owner;                                      // ������� ���������������� ����
    mapping(address => address) public organizations;   // NodeAddress => ContractAdress
    
    constructor() public {
        owner = msg.sender;
        storageAddr = address(new StorageHash());
        verificationAddr = address(new VerificationTemplate());
    }
    
    function createOrganization(address _owner, string _nameOfOrganization) 
    onlyOwner public returns(address)                   // ���������� ����� �����������
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

contract VerificationTemplate is Ownable                // ���������������� �������
{
    uint indexTemplate = 0;
    
    struct StorageTemplate {
        address OrganizationAddr;                       // �����������
        bool confirmed;                                 // ���������������� �������
    }
    
    mapping(uint => StorageTemplate) verifications;     // ������ => (���������, ����������������)
    mapping(address => bool) admins;                    // ��������������
    
    function getIndexTemplate() public payable returns(uint) {      // ���������� ������ �������
        verifications[indexTemplate] = StorageTemplate(msg.sender, false);  // � ���������� ��� �������
        return indexTemplate++;
    }
    
    function confirm(uint indexTemp) public {           // ������������� �����������
        require(admins[msg.sender]);
        StorageTemplate temp = verifications[indexTemp];
        temp.confirmed = true;
        verifications[indexTemp] = temp;
    }
    
    function addAdmin(address _adminAddr) onlyOwner {   // ���������� ��������������
        admins[_adminAddr] = true;
    }
    
    function banAdmin(address _adminAddr) onlyOwner {   // �������� ��������������
        delete admins[_adminAddr];
    }
    
}

contract Organization {
    string nameOfOrganization;      // �������� �����������
    address owner;                  // ���� ���������
    address storageAddr;            // ������ ��������� ��� ������
    address verificationAddr;       // ������ ��� ����������� ��������
    address fish = 0x0;

    mapping(address => bool) nodesOfOrganization; // ���� ������������
    mapping(uint => Template) templates; // idTemplate => Template �������
    mapping(uint => Certificate) certificates; // idCertificate => Certificate �����������

    uint amountCertificate = 0;     // �������������� �������
    
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
        uint timeOfAction;      // ���� ��������
        string nameOfTemplate;  // ��������
        uint amountField;       // ���������� ����� ��� ���������� � �������
    }
    
    struct Certificate {
        uint idCertificate;
        uint idTemplate;
        address addrToOrganization; // ���� ������������� (���� ����������� ���������������� � �������)
        uint timeOfCreate;          //����� ��������+
        bytes32 certificateHash;
        string dataArray;           // ������ � ������ ��� ���������� � �������
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
        if (now > (myCertificate.timeOfCreate + timeOfAction)) //�������� �� ����������������
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
