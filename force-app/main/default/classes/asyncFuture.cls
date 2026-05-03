public class asyncFuture {

    @Future
    public static void meth(){
        ContentNote cn = [select Id,  Title, TextPreview from ContentNote where Id = '069ak00000KTEwvAAH'];
		System.debug(cn);
    }
}