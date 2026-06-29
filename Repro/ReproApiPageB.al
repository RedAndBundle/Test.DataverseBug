page 50101 "Repro API Page B"
{
    PageType = API;
    APIPublisher = 'cronus';        // lowercase — differs from Page A's 'Cronus'
    APIGroup = 'salesData';         // lowercase 's' — differs from Page A's 'SalesData'
    APIVersion = 'v1.0';
    EntityName = 'reproItemB';
    EntitySetName = 'reproItemsB';
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
