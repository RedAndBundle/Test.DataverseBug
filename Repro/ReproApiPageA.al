page 50100 "Repro API Page A"
{
    PageType = API;
    APIPublisher = 'Cronus';
    APIGroup = 'SalesData';
    APIVersion = 'v1.0';
    EntityName = 'reproItemA';
    EntitySetName = 'reproItemsA';
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
