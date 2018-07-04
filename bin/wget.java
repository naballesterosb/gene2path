import java.io.*;
import java.net.*;
 
public class wget {
  public static void main(String[] args) throws Exception {
    String s;
    BufferedReader r = new BufferedReader(new InputStreamReader(new URL(args[0]).openStream()));
    while ((s = r.readLine()) != null) {
        System.out.println(s);
    }
  }
}