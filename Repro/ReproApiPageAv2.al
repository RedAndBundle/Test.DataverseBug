page 50102 "Repro API Page A v2"
{
    PageType = API;
    APIPublisher = 'cronus';
    APIGroup = 'salesData';
    APIVersion = 'v2.0';
    EntityName = 'reproItemA2';
    EntitySetName = 'reproItemsA2';
    SourceTable = Customer;
    ODataKeyFields = SystemId;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { }
                field(no; Rec."No.") { }
                field(name; Rec.Name) { }
            }
        }
    }
}
